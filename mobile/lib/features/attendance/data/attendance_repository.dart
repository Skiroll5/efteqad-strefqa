import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/database/app_database.dart';

// Simple data class for record with student name
class AttendanceRecordWithStudent {
  final AttendanceRecord?
  record; // Nullable to represent students without a record
  final String studentName;
  final String studentId;

  AttendanceRecordWithStudent({
    this.record,
    required this.studentName,
    required this.studentId,
  });
}

class StudentAttendanceStats {
  final String studentId;
  final int totalRecords;
  final int presentCount;
  final int absentCount;
  final int consecutiveAbsences;

  StudentAttendanceStats({
    required this.studentId,
    required this.totalRecords,
    required this.presentCount,
    required this.absentCount,
    required this.consecutiveAbsences,
  });

  // If a student has no records (e.g. new arrival), they have 0 absences.
  // Therefore, they are considered to have 100% attendance by default.
  double get presencePercentage =>
      totalRecords == 0 ? 100.0 : (presentCount / totalRecords) * 100.0;

  bool get isCritical => absentCount >= 3; // Example rule, customizable
}

class AttendanceRepository {
  final AppDatabase _db;

  AttendanceRepository(this._db);

  // Watch aggregated stats for all students in a class
  Stream<Map<String, StudentAttendanceStats>> watchClassStudentStats(
    String classId,
  ) {
    // 1. Get all students in this class
    final studentsStream =
        (_db.select(_db.students)..where(
              (s) => s.classId.equals(classId) & s.isDeleted.equals(false),
            ))
            .watch();

    // 2. Get all sessions for this class
    final sessionsStream =
        (_db.select(_db.attendanceSessions)..where(
              (s) => s.classId.equals(classId) & s.isDeleted.equals(false),
            ))
            .watch();

    // 3. Get all records for sessions in this class
    final recordsQuery =
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
    final recordsStream = recordsQuery.watch();

    return Rx.combineLatest3(studentsStream, sessionsStream, recordsStream, (
      students,
      sessions,
      recordRows,
    ) {
      final records = recordRows
          .map((r) => r.readTable(_db.attendanceRecords))
          .toList();

      final statsMap = <String, StudentAttendanceStats>{};

      for (final student in students) {
        final studentRecords = records
            .where((r) => r.studentId == student.id && !r.isDeleted)
            .toList();

        // Explicitly count records based on status to ensure we only include valid attendance data
        final presentRecords = studentRecords.where(
          (r) => r.status == 'PRESENT',
        );
        final absentRecords = studentRecords.where((r) => r.status == 'ABSENT');

        final presentCount = presentRecords.length;
        final absentCount = absentRecords.length;
        final totalRecords = presentCount + absentCount;

        // Calculate consecutive absences
        // We only care about sessions where the student DOES have a record.
        // Sort records by session date (requires mapping session ID to date)

        // 1. Map sessionId -> Date from the sessions list
        final sessionDates = <String, DateTime>{};
        for (final s in sessions) {
          sessionDates[s.id] = s.date;
        }

        // 2. Filter records that correspond to valid sessions and sort them descending
        final validRecords =
            studentRecords
                .where((r) => sessionDates.containsKey(r.sessionId))
                .toList()
              ..sort((a, b) {
                final dateA = sessionDates[a.sessionId]!;
                final dateB = sessionDates[b.sessionId]!;
                return dateB.compareTo(dateA); // Newest first
              });

        int consecutiveAbsences = 0;
        for (final record in validRecords) {
          if (record.status == 'PRESENT') {
            break;
          } else if (record.status == 'ABSENT') {
            consecutiveAbsences++;
          }
        }

        statsMap[student.id] = StudentAttendanceStats(
          studentId: student.id,
          totalRecords: totalRecords,
          presentCount: presentCount,
          absentCount: absentCount,
          consecutiveAbsences: consecutiveAbsences,
        );
      }

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
  // Shows all students belonging to the class at that time
  Stream<List<AttendanceRecordWithStudent>> watchRecordsWithStudents(
    String sessionId,
  ) {
    // First get the session info
    final sessionQuery = _db.select(_db.attendanceSessions)
      ..where((s) => s.id.equals(sessionId));

    return sessionQuery.watchSingle().switchMap((session) {
      final query =
          _db.select(_db.students).join([
            leftOuterJoin(
              _db.attendanceRecords,
              _db.attendanceRecords.studentId.equalsExp(_db.students.id) &
                  _db.attendanceRecords.sessionId.equals(sessionId) &
                  _db.attendanceRecords.isDeleted.equals(false),
            ),
          ])..where(
            _db.students.classId.equals(session.classId) &
                _db.students.isDeleted.equals(false),
          );

      return query.watch().map((rows) {
        final results = rows.map((row) {
          final record = row.readTableOrNull(_db.attendanceRecords);
          final student = row.readTable(_db.students);
          return AttendanceRecordWithStudent(
            record: record,
            studentName: student.name,
            studentId: student.id,
          );
        }).toList();

        // Sort by name
        results.sort((a, b) => a.studentName.compareTo(b.studentName));
        return results;
      });
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

    // First, get the record to include sessionId and studentId in payload
    // This is required for the server-side upsert to work if the record needs to be created
    final record = await (_db.select(
      _db.attendanceRecords,
    )..where((r) => r.id.equals(recordId))).getSingle();

    await (_db.update(
      _db.attendanceRecords,
    )..where((r) => r.id.equals(recordId))).write(
      AttendanceRecordsCompanion(
        status: Value(newStatus),
        updatedAt: Value(now),
      ),
    );

    // Add to sync queue with FULL payload
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
              'sessionId': record.sessionId,
              'studentId': record.studentId,
              'status': newStatus,
              'updatedAt': now.toIso8601String(),
            }),
            createdAt: now,
          ),
        );
  }

  // Create a new attendance record for a student
  Future<void> createRecord({
    required String sessionId,
    required String studentId,
    required String status,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();

    await _db
        .into(_db.attendanceRecords)
        .insert(
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

    // Add to sync queue
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            uuid: const Uuid().v4(),
            entityType: 'ATTENDANCE',
            entityId: id,
            operation: 'CREATE',
            payload: jsonEncode({
              'id': id,
              'sessionId': sessionId,
              'studentId': studentId,
              'status': status,
              'createdAt': now.toIso8601String(),
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

  // Delete a single attendance record by ID
  Future<void> deleteRecord(String recordId) async {
    final now = DateTime.now();

    await (_db.update(
      _db.attendanceRecords,
    )..where((r) => r.id.equals(recordId))).write(
      AttendanceRecordsCompanion(
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
            entityType: 'ATTENDANCE',
            entityId: recordId,
            operation: 'DELETE',
            payload: jsonEncode({
              'id': recordId,
              'deletedAt': now.toIso8601String(),
            }),
            createdAt: now,
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

  // Watch average class attendance percentage
  Stream<double> watchClassAttendancePercentage(String classId) {
    // Join sessions and records to get all records for this class
    final query =
        _db.select(_db.attendanceSessions).join([
          innerJoin(
            _db.attendanceRecords,
            _db.attendanceRecords.sessionId.equalsExp(
                  _db.attendanceSessions.id,
                ) &
                _db.attendanceRecords.isDeleted.equals(false),
          ),
        ])..where(
          _db.attendanceSessions.classId.equals(classId) &
              _db.attendanceSessions.isDeleted.equals(false),
        );

    return query.watch().map((rows) {
      if (rows.isEmpty) return 0.0;

      int present = 0;
      int total = 0;

      for (final row in rows) {
        final record = row.readTable(_db.attendanceRecords);
        // Only count explicit PRESENT/ABSENT statuses if there are others
        // Assuming 'PRESENT' and 'ABSENT' are the main ones.
        if (record.status == 'PRESENT') {
          present++;
          total++;
        } else if (record.status == 'ABSENT') {
          total++;
        }
      }

      if (total == 0) return 0.0;
      return (present / total) * 100.0;
    });
  }
}

class AttendanceRecordWithSession {
  final AttendanceRecord record;
  final AttendanceSession session;

  AttendanceRecordWithSession({required this.record, required this.session});
}
