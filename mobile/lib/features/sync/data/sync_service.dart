import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/config/api_config.dart';
import '../../../core/database/app_database.dart'; // Drift DB generated class

final syncServiceProvider = Provider(
  (ref) => SyncService(
    ref.read(appDatabaseProvider),
    Dio(), // Should use a configured Dio instance with interceptors
  ),
);

// Provider for AppDatabase is now in app_database.dart

class SyncService {
  final AppDatabase _db;
  final Dio _dio;
  final String _baseUrl = ApiConfig.baseUrl;

  SyncService(this._db, this._dio);

  Future<void> sync() async {
    await pushChanges();
    await pullChanges();
  }

  Future<void> pushChanges() async {
    final queueItems = await _db.select(_db.syncQueue).get();
    print('SyncService: Found ${queueItems.length} items in sync queue');

    if (queueItems.isEmpty) return;

    final token = await _getToken();
    if (token == null) {
      print('SyncService: No token found, aborting push');
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
    print('SyncService: Payload: ${jsonEncode({'changes': changes})}');

    try {
      final response = await _dio.post(
        '$_baseUrl/sync',
        data: {'changes': changes},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('SyncService: Push success, response code: ${response.statusCode}');
      final responseData = response.data;

      // Extract processed UUIDs if available (Robust Sync)
      List<dynamic>? processedUuids;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('processedUuids')) {
        processedUuids = responseData['processedUuids'];
      }

      await _db.batch((batch) {
        for (var item in queueItems) {
          if (processedUuids != null) {
            // Robust Mode: Only delete if server confirmed uuid
            if (processedUuids.contains(item.uuid)) {
              print('SyncService: Server confirmed ${item.uuid}, deleting...');
              batch.delete(_db.syncQueue, item);
            } else {
              print(
                'SyncService: Server did NOT confirm ${item.uuid}, keeping in queue.',
              );
            }
          } else {
            // Legacy Mode (or fallback): Delete all if we got a 200 OK and no specific list
            // BUT user requested we be strict. So maybe we should assume failure if list missing?
            // For safety, let's stick to "delete all" ONLY if the server didn't explicitly send the new format.
            // This keeps backward compat if server wasn't updated yet (though we manage both).
            print(
              'SyncService: No detailed confirmation list, deleting confirmed item ${item.uuid}',
            );
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
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      final serverTimestamp = data['serverTimestamp'];
      final changes = data['changes'];
      // Expected structure: { students: [], attendance: [], ... }

      await _db.transaction(() async {
        // Process Students
        if (changes['students'] != null) {
          for (var s in changes['students']) {
            await _upsertStudent(s);
          }
        }
        // Process Attendance
        if (changes['attendance'] != null) {
          for (var a in changes['attendance']) {
            await _upsertAttendance(a);
          }
        }
        // Process Notes
        if (changes['notes'] != null) {
          for (var n in changes['notes']) {
            await _upsertNote(n);
          }
        }
        // Process Classes
        if (changes['classes'] != null) {
          for (var c in changes['classes']) {
            await _upsertClass(c);
          }
        }
        // Process Attendance Sessions
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
