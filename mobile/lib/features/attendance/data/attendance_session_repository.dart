import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

final attendanceSessionRepositoryProvider =
    Provider<AttendanceSessionRepository>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return AttendanceSessionRepository(db);
    });

class AttendanceSessionRepository {
  final AppDatabase _db;
  const AttendanceSessionRepository(this._db);

  // Watch all sessions for a class
  Stream<List<AttendanceSession>> watchSessionsForClass(String classId) {
    return (_db.select(_db.attendanceSessions)
          ..where((s) => s.classId.equals(classId) & s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  // Get a single session by ID
  Future<AttendanceSession?> getSession(String sessionId) {
    return (_db.select(
      _db.attendanceSessions,
    )..where((s) => s.id.equals(sessionId))).getSingleOrNull();
  }

  // Create a new session
  Future<AttendanceSession> createSession({
    required String classId,
    required DateTime date,
    String? note,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();

    final session = AttendanceSessionsCompanion.insert(
      id: id,
      classId: classId,
      date: date,
      note: Value(note),
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.attendanceSessions).insert(session);

    // Add to sync queue
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            uuid: const Uuid().v4(),
            entityType: 'ATTENDANCE_SESSION',
            entityId: id,
            operation: 'CREATE',
            payload: jsonEncode({
              'id': id,
              'classId': classId,
              'date': date.toIso8601String(),
              'note': note,
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
            }),
            createdAt: now,
          ),
        );

    return (await getSession(id))!;
  }

  // Update a session
  Future<void> updateSession(AttendanceSession session) async {
    final now = DateTime.now();

    await (_db.update(
      _db.attendanceSessions,
    )..where((s) => s.id.equals(session.id))).write(
      AttendanceSessionsCompanion(
        note: Value(session.note),
        date: Value(session.date),
        updatedAt: Value(now),
      ),
    );

    // Add to sync queue
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            uuid: const Uuid().v4(),
            entityType: 'ATTENDANCE_SESSION',
            entityId: session.id,
            operation: 'UPDATE',
            payload: jsonEncode({
              'id': session.id,
              'classId': session.classId,
              'date': session.date.toIso8601String(),
              'note': session.note,
              'updatedAt': now.toIso8601String(),
            }),
            createdAt: now,
          ),
        );
  }

  // Soft delete a session
  Future<void> deleteSession(String sessionId) async {
    final now = DateTime.now();

    await (_db.update(
      _db.attendanceSessions,
    )..where((s) => s.id.equals(sessionId))).write(
      AttendanceSessionsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    // Add to sync queue
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            uuid: const Uuid().v4(),
            entityType: 'ATTENDANCE_SESSION',
            entityId: sessionId,
            operation: 'DELETE',
            payload: jsonEncode({'id': sessionId, 'isDeleted': true}),
            createdAt: now,
          ),
        );
  }
}
