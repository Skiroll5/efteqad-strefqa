import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/config/api_config.dart';
import '../../../core/database/app_database.dart';

/// Provider for the SyncService with auto-sync capability
final syncServiceProvider = Provider((ref) {
  final service = SyncService(ref.read(appDatabaseProvider), Dio());
  // Start watching the sync queue for auto-sync
  service.startAutoSync();
  return service;
});

/// Connectivity state provider - tracks if we can reach the server
final isOnlineProvider = StateProvider<bool>((ref) => true);

class SyncService {
  final AppDatabase _db;
  final Dio _dio;
  final String _baseUrl = ApiConfig.baseUrl;

  StreamSubscription? _queueSubscription;
  bool _isSyncing = false;
  Timer? _retryTimer;

  SyncService(this._db, this._dio);

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
    Future.delayed(const Duration(seconds: 2), () {
      sync();
    });
  }

  /// Stop auto-sync (call when disposing)
  void dispose() {
    _queueSubscription?.cancel();
    _retryTimer?.cancel();
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
            await _upsertStudent(s);
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
            await _upsertClass(c);
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
      rethrow;
    }
  }

  Future<void> _upsertStudent(Map<String, dynamic> data) async {
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

  Future<void> _upsertClass(Map<String, dynamic> data) async {
    final entity = ClassesCompanion(
      id: Value(data['id']),
      name: Value(data['name']),
      grade: Value(data['grade']),
      createdAt: Value(DateTime.parse(data['createdAt'])),
      updatedAt: Value(DateTime.parse(data['updatedAt'])),
      isDeleted: Value(data['isDeleted'] ?? false),
      deletedAt: Value(
        data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      ),
    );
    await _db.into(_db.classes).insertOnConflictUpdate(entity);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
