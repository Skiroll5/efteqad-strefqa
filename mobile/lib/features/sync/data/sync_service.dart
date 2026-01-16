import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/database/app_database.dart';
import '../../classes/data/classes_repository.dart';
import '../../classes/data/classes_controller.dart';
import '../../students/data/students_repository.dart';
import '../../students/data/students_controller.dart';
import '../../auth/data/auth_controller.dart';

/// Provider for the SyncService with auto-sync capability
final syncServiceProvider = Provider((ref) {
  final service = SyncService(
    ref.read(appDatabaseProvider),
    Dio(),
    ref.read(classesRepositoryProvider),
    ref.read(studentsRepositoryProvider),
    ref,
  );
  // Start watching the sync queue for auto-sync
  service.startAutoSync();
  // Ensure disposal when provider is disposed
  ref.onDispose(() => service.dispose());
  return service;
});

/// Connectivity state provider - tracks if we can reach the server
final isOnlineProvider = StateProvider<bool>((ref) => true);

class SyncService {
  final AppDatabase _db;
  final Dio _dio;
  final ClassesRepository _classesRepo;
  final StudentsRepository _studentsRepo;
  final Ref _ref;
  final String _baseUrl = ApiConfig.baseUrl;

  StreamSubscription? _queueSubscription;
  bool _isSyncing = false;
  Timer? _retryTimer;
  IO.Socket? _socket;

  SyncService(
    this._db,
    this._dio,
    this._classesRepo,
    this._studentsRepo,
    this._ref,
  );

  /// Start watching the sync queue and auto-push when items are added
  void startAutoSync() {
    // Watch the sync queue table for changes
    _queueSubscription?.cancel();
    _queueSubscription = _db.select(_db.syncQueue).watch().listen((items) {
      if (items.isNotEmpty && !_isSyncing) {
        // Debounce: wait a bit for potential batch inserts
        Future.delayed(const Duration(milliseconds: 500), () {
          _tryPushChanges();
        });
      }
    });

    // Also do an initial sync on startup
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await sync();
      } catch (e) {
        print('SyncService: Initial sync failed: $e');
      }
    });

    // Real-time Sync with Socket.io
    _initSocket();
  }

  void _initSocket() {
    print('SyncService: Initializing Socket.io connection to $_baseUrl');
    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() // We connect manually
          .build(),
    );

    _socket?.onConnect((_) {
      print('SyncService: Socket Connected');
    });

    _socket?.onDisconnect((_) {
      print('SyncService: Socket Disconnected');
    });

    _socket?.on('sync_update', (_) async {
      print('SyncService: Received sync_update event from server');
      if (!_isSyncing) {
        try {
          await pullChanges();
        } catch (e) {
          print('SyncService: Automatic pull failed: $e');
        }
      }
    });

    _socket?.connect();
  }

  /// Stop auto-sync (call when disposing)
  void dispose() {
    _queueSubscription?.cancel();
    _retryTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
  }

  /// Try to push changes, silently fails and retries later if offline
  Future<void> _tryPushChanges() async {
    if (_isSyncing) return;

    try {
      await pushChanges();
      // If successful, also pull changes
      await pullChanges();
    } catch (e) {
      print('AutoSync: Push failed, will retry later: $e');
      // Schedule a retry after 30 seconds
      _scheduleRetry();
    }
  }

  /// Schedule a retry for failed sync
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      _tryPushChanges();
    });
  }

  /// Manually trigger a full sync
  Future<void> sync() async {
    await pushChanges();
    await pullChanges();
  }

  Future<void> pushChanges() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queueItems = await _db.select(_db.syncQueue).get();
      print('SyncService: Found ${queueItems.length} items in sync queue');

      if (queueItems.isEmpty) {
        _isSyncing = false;
        return;
      }

      final token = await _getToken();
      if (token == null) {
        print('SyncService: No token found, aborting push');
        _isSyncing = false;
        return;
      }

      // Transform to payload
      final changes = queueItems.map((item) {
        return {
          'uuid': item.uuid,
          'entityType': item.entityType,
          'entityId': item.entityId,
          'operation': item.operation,
          'payload': jsonDecode(item.payload),
          'createdAt': item.createdAt.toIso8601String(),
        };
      }).toList();

      print('SyncService: Pushing ${changes.length} changes to $_baseUrl/sync');

      final response = await _dio.post(
        '$_baseUrl/sync',
        data: {'changes': changes},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      print('SyncService: Push success, response code: ${response.statusCode}');
      final responseData = response.data;

      // Extract processed UUIDs if available
      List<dynamic>? processedUuids;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('processedUuids')) {
        processedUuids = responseData['processedUuids'];
      }

      await _db.batch((batch) {
        for (var item in queueItems) {
          if (processedUuids != null) {
            if (processedUuids.contains(item.uuid)) {
              batch.delete(_db.syncQueue, item);
            }
          } else {
            // Legacy fallback: delete all on success
            batch.delete(_db.syncQueue, item);
          }
        }
      });

      print('SyncService: Queue processing complete');
    } catch (e) {
      print('SyncService: Push failed: $e');
      if (e is DioException) {
        print('SyncService: DioError: ${e.response?.data}');
        // Auto-logout on 401/403 (token expired/invalid)
        if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
          print('SyncService: Token expired/invalid, logging out user');
          await _ref.read(authControllerProvider.notifier).logout();
          // Don't rethrow on auth errors since we've handled it by logging out
          return;
        }
      }
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> pullChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('last_sync_timestamp');

    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await _dio.get(
        '$_baseUrl/sync',
        queryParameters: lastSync != null ? {'since': lastSync} : null,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final data = response.data;
      final serverTimestamp = data['serverTimestamp'];
      final changes = data['changes'];

      await _db.transaction(() async {
        if (changes['students'] != null) {
          for (var s in changes['students']) {
            await _studentsRepo.upsertStudentFromSync(s);
          }
        }
        if (changes['attendance'] != null) {
          for (var a in changes['attendance']) {
            await _upsertAttendance(a);
          }
        }
        if (changes['notes'] != null) {
          for (var n in changes['notes']) {
            await _upsertNote(n);
          }
        }
        if (changes['classes'] != null) {
          for (var c in changes['classes']) {
            await _classesRepo.upsertClassFromSync(c);
          }
        }
        if (changes['attendance_sessions'] != null) {
          for (var s in changes['attendance_sessions']) {
            await _upsertAttendanceSession(s);
          }
        }
      });

      await prefs.setString('last_sync_timestamp', serverTimestamp);
    } catch (e) {
      print('Pull failed: $e');
      // Auto-logout on 401/403 (token expired/invalid)
      if (e is DioException &&
          (e.response?.statusCode == 403 || e.response?.statusCode == 401)) {
        print('SyncService: Token expired/invalid, logging out user');
        await _ref.read(authControllerProvider.notifier).logout();
        // Don't rethrow on auth errors since we've handled it by logging out
        return;
      }
      rethrow;
    }
  }

  Future<void> _upsertAttendance(Map<String, dynamic> data) async {
    final entity = AttendanceRecordsCompanion(
      id: Value(data['id']),
      sessionId: Value(data['sessionId']),
      studentId: Value(data['studentId']),
      status: Value(data['status']),
      createdAt: Value(DateTime.parse(data['createdAt'])),
      updatedAt: Value(DateTime.parse(data['updatedAt'])),
      isDeleted: Value(data['isDeleted'] ?? false),
      deletedAt: Value(
        data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      ),
    );
    await _db.into(_db.attendanceRecords).insertOnConflictUpdate(entity);
  }

  Future<void> _upsertAttendanceSession(Map<String, dynamic> data) async {
    final entity = AttendanceSessionsCompanion(
      id: Value(data['id']),
      classId: Value(data['classId']),
      date: Value(DateTime.parse(data['date'])),
      note: Value(data['note']),
      createdAt: Value(DateTime.parse(data['createdAt'])),
      updatedAt: Value(DateTime.parse(data['updatedAt'])),
      isDeleted: Value(data['isDeleted'] ?? false),
      deletedAt: Value(
        data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      ),
    );
    await _db.into(_db.attendanceSessions).insertOnConflictUpdate(entity);
  }

  Future<void> _upsertNote(Map<String, dynamic> data) async {
    final entity = NotesCompanion(
      id: Value(data['id']),
      studentId: Value(data['studentId']),
      content: Value(data['content']),
      createdAt: Value(DateTime.parse(data['createdAt'])),
      updatedAt: Value(DateTime.parse(data['updatedAt'])),
      isDeleted: Value(data['isDeleted'] ?? false),
      deletedAt: Value(
        data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      ),
    );
    await _db.into(_db.notes).insertOnConflictUpdate(entity);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Clears all local data and resets sync timestamp.
  /// Useful if backend was manually reset.
  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_timestamp');

    await _db.transaction(() async {
      // Delete in correct order to avoid foreign key issues (if any)
      await _db.delete(_db.attendanceRecords).go();
      await _db.delete(_db.attendanceSessions).go();
      await _db.delete(_db.notes).go();
      await _db.delete(_db.students).go();
      await _db.delete(_db.classes).go();
      await _db.delete(_db.syncQueue).go();
    });

    print('SyncService: Local data and sync timestamp cleared');
  }
}
