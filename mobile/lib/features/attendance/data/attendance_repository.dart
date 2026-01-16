import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

// Simple data class for record with student name
class AttendanceRecordWithStudent {
  final AttendanceRecord record;
  final String studentName;

  AttendanceRecordWithStudent({
    required this.record,
    required this.studentName,
  });
}

class StudentAttendanceStats {
  final String studentId;
  final int totalRecords;
  final int presentCount;
  final int absentCount;

  StudentAttendanceStats({
    required this.studentId,
    required this.totalRecords,
    required this.presentCount,
    required this.absentCount,
  });

  double get presencePercentage =>
      totalRecords == 0 ? 0.0 : (presentCount / totalRecords) * 100.0;

  bool get isCritical => absentCount >= 3; // Example rule, customizable
}

class AttendanceRepository {
  final AppDatabase _db;

  AttendanceRepository(this._db);

  // Watch aggregated stats for all students in a class
  Stream<Map<String, StudentAttendanceStats>> watchClassStudentStats(
    String classId,
  ) {
    final query =
        _db.select(_db.attendanceRecords).join([
          innerJoin(
            _db.attendanceSessions,
            _db.attendanceSessions.id.equalsExp(
              _db.attendanceRecords.sessionId,
            ),
          ),
        ])..where(
          _db.attendanceSessions.classId.equals(classId) &
              _db.attendanceSessions.isDeleted.equals(false) &
              _db.attendanceRecords.isDeleted.equals(false),
        );

    return query.watch().map((rows) {
      final Map<String, List<AttendanceRecord>> recordsByStudent = {};

      for (final row in rows) {
        final record = row.readTable(_db.attendanceRecords);
        recordsByStudent.putIfAbsent(record.studentId, () => []).add(record);
      }

      final statsMap = <String, StudentAttendanceStats>{};
      recordsByStudent.forEach((studentId, records) {
        final present = records.where((r) => r.status == 'PRESENT').length;
        final absent = records.where((r) => r.status == 'ABSENT').length;

        statsMap[studentId] = StudentAttendanceStats(
          studentId: studentId,
          totalRecords: records.length,
          presentCount: present,
          absentCount: absent,
        );
      });

      return statsMap;
    });
  }

  // Watch attendance records for a specific session
  Stream<List<AttendanceRecord>> watchRecordsForSession(String sessionId) {
    return (_db.select(_db.attendanceRecords)..where(
          (r) => r.sessionId.equals(sessionId) & r.isDeleted.equals(false),
        ))
        .watch();
  }

  // Watch records with student names (joined)
  Stream<List<AttendanceRecordWithStudent>> watchRecordsWithStudents(
    String sessionId,
  ) {
    final query =
        _db.select(_db.attendanceRecords).join([
          innerJoin(
            _db.students,
            _db.students.id.equalsExp(_db.attendanceRecords.studentId),
          ),
        ])..where(
          _db.attendanceRecords.sessionId.equals(sessionId) &
              _db.attendanceRecords.isDeleted.equals(false),
        );

    return query.watch().map((rows) {
      return rows.map((row) {
        final record = row.readTable(_db.attendanceRecords);
        final student = row.readTable(_db.students);
        return AttendanceRecordWithStudent(
          record: record,
          studentName: student.name,
        );
      }).toList();
    });
  }

  // Get attendance records for a session (non-stream)
  Future<List<AttendanceRecord>> getRecordsForSession(String sessionId) {
    return (_db.select(_db.attendanceRecords)..where(
          (r) => r.sessionId.equals(sessionId) & r.isDeleted.equals(false),
        ))
        .get();
  }

  // Save attendance batch for a session
  Future<void> saveAttendanceBatch({
    required String sessionId,
    required Map<String, bool> attendance, // studentId -> isPresent
  }) async {
    final now = DateTime.now();

    await _db.batch((batch) {
      attendance.forEach((studentId, isPresent) {
        final id = const Uuid().v4();
        final status = isPresent ? 'PRESENT' : 'ABSENT';

        batch.insert(
          _db.attendanceRecords,
          AttendanceRecordsCompanion(
            id: Value(id),
            sessionId: Value(sessionId),
            studentId: Value(studentId),
            status: Value(status),
            isDeleted: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        // Add to SyncQueue
        batch.insert(
          _db.syncQueue,
          SyncQueueCompanion(
            uuid: Value(const Uuid().v4()),
            entityType: const Value('ATTENDANCE'),
            entityId: Value(id),
            operation: const Value('CREATE'),
            payload: Value(
              jsonEncode({
                'id': id,
                'sessionId': sessionId,
                'studentId': studentId,
                'status': status,
                'createdAt': now.toIso8601String(),
                'updatedAt': now.toIso8601String(),
              }),
            ),
            createdAt: Value(now),
          ),
        );
      });
    });
  }

  // Update a single attendance record
  Future<void> updateRecord(String recordId, String newStatus) async {
    final now = DateTime.now();

    await (_db.update(
      _db.attendanceRecords,
    )..where((r) => r.id.equals(recordId))).write(
      AttendanceRecordsCompanion(
        status: Value(newStatus),
        updatedAt: Value(now),
      ),
    );

    // Add to sync queue
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            uuid: const Uuid().v4(),
            entityType: 'ATTENDANCE',
            entityId: recordId,
            operation: 'UPDATE',
            payload: jsonEncode({
              'id': recordId,
              'status': newStatus,
              'updatedAt': now.toIso8601String(),
            }),
            createdAt: now,
          ),
        );
  }

  // Delete all records for a session (usually when deleting the session)
  Future<void> deleteRecordsForSession(String sessionId) async {
    final now = DateTime.now();

    await (_db.update(
      _db.attendanceRecords,
    )..where((r) => r.sessionId.equals(sessionId))).write(
      AttendanceRecordsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  // --- New Features ---

  // Mark a student absent for all past sessions in a class (Retroactive Absence)
  Future<void> markStudentAbsentForPastSessions({
    required String studentId,
    required String classId,
  }) async {
    final now = DateTime.now();

    // 1. Get all sessions for this class that are in the past
    final sessions =
        await (_db.select(_db.attendanceSessions)..where(
              (s) =>
                  s.classId.equals(classId) &
                  s.date.isSmallerThanValue(now) &
                  s.isDeleted.equals(false),
            ))
            .get();

    if (sessions.isEmpty) return;

    await _db.batch((batch) {
      for (final session in sessions) {
        final id = const Uuid().v4();
        // Check if record already exists? Ideally we assume new student has none.
        // But safe to ignore if collision (unlikely with UUID) or check first.
        // For simplicity and performance, we'll blindly insert. Unique constraint on (sessionId, studentId) would be good in schema but we use UUID PK.
        // We will just insert.

        batch.insert(
          _db.attendanceRecords,
          AttendanceRecordsCompanion(
            id: Value(id),
            sessionId: Value(session.id),
            studentId: Value(studentId),
            status: const Value('ABSENT'),
            isDeleted: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        // Sync Queue
        batch.insert(
          _db.syncQueue,
          SyncQueueCompanion(
            uuid: Value(const Uuid().v4()),
            entityType: const Value('ATTENDANCE'),
            entityId: Value(id),
            operation: const Value('CREATE'),
            payload: Value(
              jsonEncode({
                'id': id,
                'sessionId': session.id,
                'studentId': studentId,
                'status': 'ABSENT',
                'createdAt': now.toIso8601String(),
                'updatedAt': now.toIso8601String(),
              }),
            ),
            createdAt: Value(now),
          ),
        );
      }
    });
  }

  // Watch attendance history for a specific student
  // Returns List of (Record + Session Date)
  Stream<List<AttendanceRecordWithSession>> watchStudentAttendance(
    String studentId,
  ) {
    final query =
        _db.select(_db.attendanceRecords).join([
            innerJoin(
              _db.attendanceSessions,
              _db.attendanceSessions.id.equalsExp(
                _db.attendanceRecords.sessionId,
              ),
            ),
          ])
          ..where(
            _db.attendanceRecords.studentId.equals(studentId) &
                _db.attendanceRecords.isDeleted.equals(false) &
                _db.attendanceSessions.isDeleted.equals(false),
          )
          ..orderBy([
            OrderingTerm(
              expression: _db.attendanceSessions.date,
              mode: OrderingMode.desc,
            ),
          ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final record = row.readTable(_db.attendanceRecords);
        final session = row.readTable(_db.attendanceSessions);
        return AttendanceRecordWithSession(record: record, session: session);
      }).toList();
    });
  }
}

class AttendanceRecordWithSession {
  final AttendanceRecord record;
  final AttendanceSession session;

  AttendanceRecordWithSession({required this.record, required this.session});
}
