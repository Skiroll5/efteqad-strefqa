import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/database/app_database.dart';
import '../../auth/data/auth_controller.dart';

/// Provider for the SyncService with auto-sync capability
final syncServiceProvider = Provider((ref) {
  final service = SyncService(ref.read(appDatabaseProvider), Dio(), ref);
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
  final Ref _ref;
  final String _baseUrl = ApiConfig.baseUrl;

  StreamSubscription? _queueSubscription;
  bool _isSyncing = false;
  Timer? _retryTimer;
  io.Socket? _socket;

  SyncService(this._db, this._dio, this._ref);

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
        // print('SyncService: Initial sync failed: $e');
      }
    });

    // Real-time Sync with Socket.io
    _initSocket();
  }

  void _initSocket() {
    print('SyncService: Initializing Socket.io connection to $_baseUrl');
    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() // We connect manually
          .enableReconnection() // Reconnect on disconnect
          .setReconnectionAttempts(99999)
          .setReconnectionDelay(1000)
          .enableForceNew()
          .build(),
    );

    _socket?.onConnect((_) {
      print('SyncService: Socket Connected');
      // Pull changes on reconnect to catch up
      if (!_isSyncing) {
        pullChanges().catchError((_) {});
      }
    });

    _socket?.onDisconnect((_) {
      print('SyncService: Socket Disconnected');
    });

    _socket?.on('connect_error', (data) {
      print('SyncService: Connection Error: $data');
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

    // Listen for user disabled event - auto logout
    _socket?.on('user_disabled', (data) async {
      print('SyncService: Received user_disabled: $data');
      if (data != null && data['userId'] != null) {
        final currentUser = _ref.read(authControllerProvider).asData?.value;
        if (currentUser != null && currentUser.id == data['userId']) {
          // User was disabled, logout immediately
          print('SyncService: Logging out disabled user');
          await _ref.read(authControllerProvider.notifier).logout();
        }
      }
    });

    // Listen for user deleted event - auto logout
    _socket?.on('user_deleted', (data) async {
      print('SyncService: Received user_deleted: $data');
      if (data != null && data['userId'] != null) {
        final currentUser = _ref.read(authControllerProvider).asData?.value;
        if (currentUser != null && currentUser.id == data['userId']) {
          print('SyncService: Logging out deleted user');
          await _ref.read(authControllerProvider.notifier).logout();
        }
      }
    });

    // Listen for user status changes to refresh providers
    _socket?.on('user_status_changed', (data) async {
      print('SyncService: Received user_status_changed: $data');
      if (!_isSyncing) {
        try {
          await pullChanges();
        } catch (e) {
          // Silently fail
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
      // print('AutoSync: Push failed, will retry later: $e');
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

  /// Try to perform an action online first, falling back to local+queue if failed
  Future<void> trySyncFirst({
    required Future<void> Function() performOnline,
    required Future<void> Function() performLocal,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    try {
      // 1. Try Online
      await performOnline();

      // 2. Success: Perform Local Write (without queueing)
      await performLocal();

      // Optional: Pull changes to get any server-side computed fields / triggers
      // catchError to ensure we don't block UI if pull fails
      pullChanges().catchError((_) {});
    } catch (e) {
      // 3. Failure: Check if we should fallback
      // If it's a client error (4xx), rethrow (e.g. validation failed) unless it's 408 (Timeout)
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode != null &&
            statusCode >= 400 &&
            statusCode < 500 &&
            statusCode != 408) {
          rethrow;
        }
      }

      // Fallback: Local Write + Queue
      await _db.transaction(() async {
        await performLocal();
        await enqueue(
          entityType: entityType,
          entityId: entityId,
          operation: operation,
          payload: payload,
        );
      });
    }
  }

  /// Add an item to the sync queue
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion(
            uuid: Value(const Uuid().v4()),
            entityType: Value(entityType),
            entityId: Value(entityId),
            operation: Value(operation),
            payload: Value(jsonEncode(payload)),
            createdAt: Value(DateTime.now()),
          ),
        );

    // Trigger auto-sync attempt (debounced by listener)
    // The listener on `syncQueue` in `startAutoSync` will pick this up
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
      // print('SyncService: Found ${queueItems.length} items in sync queue');

      if (queueItems.isEmpty) {
        _isSyncing = false;
        return;
      }

      final token = await _getToken();
      if (token == null) {
        // print('SyncService: No token found, aborting push');
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

      // print('SyncService: Pushing ${changes.length} changes to $_baseUrl/sync');

      final response = await _dio.post(
        '$_baseUrl/sync',
        data: {'changes': changes},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      // print('SyncService: Push success, response code: ${response.statusCode}');
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

      // print('SyncService: Queue processing complete');
    } catch (e) {
      // print('SyncService: Push failed: $e');
      if (e is DioException) {
        // print('SyncService: DioError: ${e.response?.data}');
        // Auto-logout on 401/403 (token expired/invalid)
        if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
          // print('SyncService: Token expired/invalid, logging out user');
          await _ref.read(authControllerProvider.notifier).logout();
          // Don't rethrow on auth errors since we've handled it by logging out
          return;
        }
        // Silently swallow connection/timeout errors - these are expected when offline
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError) {
          // Will retry later via _scheduleRetry
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
        // Sync Users first (for foreign keys)
        if (changes['users'] != null) {
          for (var u in changes['users']) {
            await _upsertUser(u);
          }
        }
        if (changes['students'] != null) {
          for (var s in changes['students']) {
            await _upsertStudentFromSync(s);
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
          print('SyncService: Received ${(changes['classes'] as List).length} classes to sync');
          for (var c in changes['classes']) {
            await _upsertClassFromSync(c);
          }
        } else {
          print('SyncService: No classes in sync response');
        }
        if (changes['attendance_sessions'] != null) {
          for (var s in changes['attendance_sessions']) {
            await _upsertAttendanceSession(s);
          }
        }
        // Class Managers table removed for security - no longer synced
      });

      await prefs.setString('last_sync_timestamp', serverTimestamp);
    } catch (e) {
      // Auto-logout on 401/403 (token expired/invalid)
      if (e is DioException) {
        if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
          // print('SyncService: Token expired/invalid, logging out user');
          await _ref.read(authControllerProvider.notifier).logout();
          // Don't rethrow on auth errors since we've handled it by logging out
          return;
        }
        // Silently swallow connection/timeout errors - these are expected when offline
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError) {
          // print('SyncService: Network error during pull, will retry later');
          return;
        }
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
      authorId: Value(data['authorId']),
      authorName: Value(data['authorName']), // De-normalized
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

  Future<void> _upsertUser(Map<String, dynamic> data) async {
    final entity = UsersCompanion(
      id: Value(data['id']),
      email: Value(data['email']),
      name: Value(data['name']),
      role: Value(data['role']),
      classId: Value(data['classId']),
      whatsappTemplate: Value(data['whatsappTemplate']),
      isActive: Value(data['isActive'] ?? false),
      isEnabled: Value(data['isEnabled'] ?? true),
      activationDenied: Value(data['activationDenied'] ?? false),
      createdAt: Value(DateTime.parse(data['createdAt'])),
      updatedAt: Value(DateTime.parse(data['updatedAt'])),
      isDeleted: Value(data['isDeleted'] ?? false),
      deletedAt: Value(
        data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      ),
    );
    await _db.into(_db.users).insertOnConflictUpdate(entity);
  }

  // ClassManager upsert removed

  Future<void> _upsertClassFromSync(Map<String, dynamic> data) async {
    // DEBUG: Log incoming class data
    print('SyncService _upsertClassFromSync: id=${data['id']}, name=${data['name']}, managerNames=${data['managerNames']}');
    
    final entity = ClassesCompanion(
      id: Value(data['id']),
      name: Value(data['name']),
      grade: Value(data['grade']),
      managerNames: Value(data['managerNames']), // De-normalized
      createdAt: Value(DateTime.parse(data['createdAt'])),
      updatedAt: Value(DateTime.parse(data['updatedAt'])),
      isDeleted: Value(data['isDeleted'] ?? false),
      deletedAt: Value(
        data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      ),
    );
    await _db.into(_db.classes).insertOnConflictUpdate(entity);
  }

  Future<void> _upsertStudentFromSync(Map<String, dynamic> data) async {
    final entity = StudentsCompanion(
      id: Value(data['id']),
      name: Value(data['name']),
      phone: Value(data['phone']),
      address: Value(data['address']),
      birthdate: Value(
        data['birthdate'] != null ? DateTime.parse(data['birthdate']) : null,
      ),
      classId: Value(data['classId']),
      createdAt: Value(DateTime.parse(data['createdAt'])),
      updatedAt: Value(DateTime.parse(data['updatedAt'])),
      isDeleted: Value(data['isDeleted'] ?? false),
      deletedAt: Value(
        data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      ),
    );
    await _db.into(_db.students).insertOnConflictUpdate(entity);
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

    // print('SyncService: Local data and sync timestamp cleared');
  }
}
