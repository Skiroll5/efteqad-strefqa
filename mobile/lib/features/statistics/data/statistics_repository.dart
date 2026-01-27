import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/database/app_database.dart';

import '../../settings/data/settings_controller.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.read(appDatabaseProvider));
});

final atRiskStudentsProvider = StreamProvider<List<AtRiskStudent>>((ref) {
  final repo = ref.watch(statisticsRepositoryProvider);
  final threshold = ref.watch(statisticsSettingsProvider);
  return repo.watchAtRiskStudents(threshold);
});

/// Provider for at-risk students filtered by a specific class
final classAtRiskStudentsProvider =
    StreamProvider.family<List<AtRiskStudent>, String>((ref, classId) {
      final allAtRisk = ref.watch(atRiskStudentsProvider);
      return allAtRisk.when(
        data: (students) => Stream.value(
          students.where((s) => s.student.classId == classId).toList(),
        ),
        loading: () => const Stream.empty(),
        error: (e, st) => Stream.error(e, st),
      );
    });

final weeklyStatsProvider = StreamProvider<List<WeeklyStats>>((ref) {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.watchWeeklyAttendanceStats();
});

class StatisticsRepository {
  final AppDatabase _db;

  StatisticsRepository(this._db);

  /// Watch at risk students reactive to database changes
  Stream<List<AtRiskStudent>> watchAtRiskStudents(int threshold) {
    // Watch for changes in any of the relevant tables
    final changesStream = Rx.merge([
      _db.select(_db.students).watch(),
      _db.select(_db.attendanceSessions).watch(),
      _db.select(_db.attendanceRecords).watch(),
    ]);

    // When any table changes, re-fetch the calculated data
    // Use debounce to avoid thrashing if multiple inserts happen quickly
    return changesStream
        .debounceTime(const Duration(milliseconds: 300))
        .asyncMap((_) {
          return getAtRiskStudents(threshold);
        });
  }

  /// Get students who have missed the last [threshold] consecutive sessions of their class.
  Future<List<AtRiskStudent>> getAtRiskStudents(int threshold) async {
    final atRiskList = <AtRiskStudent>[];

    // 1. Fetch all active students joined with their class info
    //    Query: SELECT s.*, c.name FROM students s LEFT JOIN classes c ON s.classId = c.id WHERE s.isDeleted = 0
    final studentsQuery = _db.select(_db.students).join([
      leftOuterJoin(
        _db.classes,
        _db.classes.id.equalsExp(_db.students.classId),
      ),
    ]);
    studentsQuery.where(_db.students.isDeleted.equals(false));

    final studentRows = await studentsQuery.get();

    // Group students by classId and store class names
    final studentsByClass = <String, List<Student>>{};
    final classNames = <String, String>{};

    for (var row in studentRows) {
      final student = row.readTable(_db.students);
      final clazz = row.readTableOrNull(_db.classes);

      if (student.classId != null) {
        studentsByClass.putIfAbsent(student.classId!, () => []).add(student);
        if (clazz != null) {
          classNames[student.classId!] = clazz.name;
        }
      }
    }

    if (studentsByClass.isEmpty) return [];

    final classIds = studentsByClass.keys.toList();

    // 2. Fetch all sessions for these classes
    //    Query: SELECT * FROM attendance_sessions WHERE classId IN (...) AND isDeleted = 0 ORDER BY date DESC
    //    We fetch all sessions to calculate total stats, not just recent ones.
    final allSessionsList =
        await (_db.select(_db.attendanceSessions)
              ..where(
                (t) => t.classId.isIn(classIds) & t.isDeleted.equals(false),
              )
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
              ]))
            .get();

    // Group sessions by classId
    final sessionsByClass = <String, List<AttendanceSession>>{};
    for (var s in allSessionsList) {
      sessionsByClass.putIfAbsent(s.classId, () => []).add(s);
    }

    // 3. Fetch all attendance records for these sessions
    final allSessionIds = allSessionsList.map((s) => s.id).toList();
    if (allSessionIds.isEmpty) return [];

    // Batch query to avoid SQLite limits (typically 999 parameters)
    final allRecords = <AttendanceRecord>[];
    const batchSize = 500;
    for (var i = 0; i < allSessionIds.length; i += batchSize) {
      final end = (i + batchSize < allSessionIds.length)
          ? i + batchSize
          : allSessionIds.length;
      final batch = allSessionIds.sublist(i, end);

      final batchRecords =
          await (_db.select(_db.attendanceRecords)..where(
                (t) => t.sessionId.isIn(batch) & t.isDeleted.equals(false),
              ))
              .get();
      allRecords.addAll(batchRecords);
    }

    // Group records by studentId for O(1) access
    final recordsByStudent = <String, List<AttendanceRecord>>{};
    for (var r in allRecords) {
      recordsByStudent.putIfAbsent(r.studentId, () => []).add(r);
    }

    // 4. Process data in memory
    for (var entry in studentsByClass.entries) {
      final classId = entry.key;
      final classStudents = entry.value;
      final className = classNames[classId];

      final classSessions = sessionsByClass[classId] ?? [];

      // Get all sessions (already sorted desc) to count true consecutive absences
      // final recentSessions = classSessions.take(threshold).toList(); // OLD: incorrectly capped count
      if (classSessions.isEmpty) continue;

      // Create a set of session IDs for this class to filter relevant records
      final classSessionIds = classSessions.map((s) => s.id).toSet();

      for (var student in classStudents) {
        final studentRecords = recordsByStudent[student.id];

        if (studentRecords == null || studentRecords.isEmpty) continue;

        // Filter records to only those belonging to this class's sessions
        final relevantRecords = studentRecords
            .where((r) => classSessionIds.contains(r.sessionId))
            .toList();

        if (relevantRecords.isEmpty) continue;

        // Calculate Attendance Percentage
        final totalSessions = relevantRecords.length;
        final totalPresences = relevantRecords
            .where((r) => r.status == 'PRESENT')
            .length;
        final attendancePercentage = totalSessions > 0
            ? (totalPresences / totalSessions) * 100
            : 0.0;

        // Calculate Consecutive Absences
        int currentConsecutive = 0;
        for (var session in classSessions) {
          final record = relevantRecords
              .where((r) => r.sessionId == session.id)
              .firstOrNull;

          if (record != null) {
            if (record.status != 'PRESENT') {
              currentConsecutive++;
            } else {
              break;
            }
          }
          // If no record, ignore this session (e.g. didn't join yet)
        }

        if (currentConsecutive >= threshold) {
          atRiskList.add(
            AtRiskStudent(
              student: student,
              consecutiveAbsences: currentConsecutive,
              className: className,
              phoneNumber: student.phone,
              totalPresences: totalPresences,
              totalSessions: totalSessions,
              attendancePercentage: attendancePercentage,
            ),
          );
        }
      }
    }

    // Sort by attendance percentage (lowest first = most at risk)
    atRiskList.sort(
      (a, b) => a.attendancePercentage.compareTo(b.attendancePercentage),
    );

    return atRiskList;
  }

  /// Get aggregated weekly attendance percentage for the last 12 weeks
  Future<List<WeeklyStats>> getWeeklyAttendanceStats() async {
    final cutoffDate = DateTime.now().subtract(
      const Duration(days: 84),
    ); // 12 weeks

    final sessions =
        await (_db.select(_db.attendanceSessions)
              ..where(
                (t) =>
                    t.date.isBiggerOrEqualValue(cutoffDate) &
                    t.isDeleted.equals(false),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.date)]))
            .get();

    if (sessions.isEmpty) return [];

    final sessionIds = sessions.map((s) => s.id).toList();

    // Batch fetch records
    final allRecords = <AttendanceRecord>[];
    const batchSize = 500;
    for (var i = 0; i < sessionIds.length; i += batchSize) {
      final end = (i + batchSize < sessionIds.length)
          ? i + batchSize
          : sessionIds.length;
      final batch = sessionIds.sublist(i, end);
      final batchRecords =
          await (_db.select(_db.attendanceRecords)..where(
                (t) => t.sessionId.isIn(batch) & t.isDeleted.equals(false),
              ))
              .get();
      allRecords.addAll(batchRecords);
    }

    // Group records by sessionId
    final recordsBySession = <String, List<AttendanceRecord>>{};
    for (var r in allRecords) {
      recordsBySession.putIfAbsent(r.sessionId, () => []).add(r);
    }

    final statsMap = <int, _WeeklyAggregator>{}; // WeekIndex -> Data

    for (var session in sessions) {
      final weekIndex =
          session.date.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24 * 7);

      final records = recordsBySession[session.id] ?? [];

      if (records.isNotEmpty) {
        final present = records.where((r) => r.status == 'PRESENT').length;
        final total = records.length;

        statsMap.putIfAbsent(weekIndex, () => _WeeklyAggregator(session.date));
        statsMap[weekIndex]!.add(present, total);
      }
    }

    return statsMap.entries.map((e) {
      return WeeklyStats(weekStart: e.value.date, attendanceRate: e.value.rate);
    }).toList()..sort((a, b) => a.weekStart.compareTo(b.weekStart));
  }

  Stream<List<WeeklyStats>> watchWeeklyAttendanceStats() {
    final changesStream = Rx.merge([
      _db.select(_db.attendanceSessions).watch(),
      _db.select(_db.attendanceRecords).watch(),
    ]);

    return changesStream
        .debounceTime(const Duration(milliseconds: 300))
        .asyncMap((_) => getWeeklyAttendanceStats());
  }
}

class _WeeklyAggregator {
  DateTime date; // Use the date of the first session as proxy for week
  int present = 0;
  int total = 0;

  _WeeklyAggregator(this.date);

  void add(int p, int t) {
    present += p;
    total += t;
  }

  double get rate => total == 0 ? 0 : (present / total) * 100;
}

class AtRiskStudent {
  final Student student;
  final String? className;
  final int consecutiveAbsences;
  final String? phoneNumber;
  final int totalPresences;
  final int totalSessions;
  final double attendancePercentage;

  AtRiskStudent({
    required this.student,
    required this.className,
    required this.consecutiveAbsences,
    this.phoneNumber,
    this.totalPresences = 0,
    this.totalSessions = 0,
    this.attendancePercentage = 0.0,
  });
}

class WeeklyStats {
  final DateTime weekStart;
  final double attendanceRate;

  WeeklyStats({required this.weekStart, required this.attendanceRate});
}
