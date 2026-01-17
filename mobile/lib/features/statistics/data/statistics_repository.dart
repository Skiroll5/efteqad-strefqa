import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

import '../../settings/data/settings_controller.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.read(appDatabaseProvider));
});

final atRiskStudentsProvider = FutureProvider<List<AtRiskStudent>>((ref) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  final threshold = ref.watch(statisticsSettingsProvider);
  return repo.getAtRiskStudents(threshold);
});

final weeklyStatsProvider = FutureProvider<List<WeeklyStats>>((ref) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getWeeklyAttendanceStats();
});

class StatisticsRepository {
  final AppDatabase _db;

  StatisticsRepository(this._db);

  /// Get students who have missed the last [threshold] consecutive sessions of their class.
  Future<List<AtRiskStudent>> getAtRiskStudents(int threshold) async {
    final atRiskList = <AtRiskStudent>[];

    // Get all active students
    final students = await (_db.select(
      _db.students,
    )..where((t) => t.isDeleted.equals(false))).get();

    // Group students by class to minimize session queries
    final studentsByClass = <String, List<Student>>{};
    for (var s in students) {
      if (s.classId != null) {
        studentsByClass.putIfAbsent(s.classId!, () => []).add(s);
      }
    }

    // Check each class
    for (var entry in studentsByClass.entries) {
      final classId = entry.key;
      final classStudents = entry.value;
      final className = (await _getClassName(classId)) ?? 'Unknown Class';

      // Get last [threshold] sessions for this class (for consecutive check)
      final recentSessions =
          await (_db.select(_db.attendanceSessions)
                ..where(
                  (t) => t.classId.equals(classId) & t.isDeleted.equals(false),
                )
                ..orderBy([
                  (t) =>
                      OrderingTerm(expression: t.date, mode: OrderingMode.desc),
                ])
                ..limit(threshold))
              .get();

      // If not enough sessions to judge, skip
      if (recentSessions.isEmpty) continue;

      final recentSessionIds = recentSessions.map((s) => s.id).toList();

      // Get ALL sessions for this class (for total stats)
      final allSessions =
          await (_db.select(_db.attendanceSessions)..where(
                (t) => t.classId.equals(classId) & t.isDeleted.equals(false),
              ))
              .get();
      final allSessionIds = allSessions.map((s) => s.id).toList();

      // For each student in this class, check attendance
      for (var student in classStudents) {
        // Check consecutive absences in recent sessions
        final recentPresentRecords =
            await (_db.select(_db.attendanceRecords)..where(
                  (t) =>
                      t.studentId.equals(student.id) &
                      t.sessionId.isIn(recentSessionIds) &
                      t.status.equals('PRESENT') &
                      t.isDeleted.equals(false),
                ))
                .get();

        // Only add to at-risk list if they missed all recent sessions
        if (recentPresentRecords.isEmpty) {
          // Get ALL attendance records for this student (to calculate total stats)
          // Only count sessions where student has a record (was enrolled at that time)
          final allStudentRecords =
              await (_db.select(_db.attendanceRecords)..where(
                    (t) =>
                        t.studentId.equals(student.id) &
                        t.sessionId.isIn(allSessionIds) &
                        t.isDeleted.equals(false),
                  ))
                  .get();

          // Total sessions = sessions where student has ANY record
          final totalSessions = allStudentRecords.length;
          final totalPresences = allStudentRecords
              .where((r) => r.status == 'PRESENT')
              .length;
          final attendancePercentage = totalSessions > 0
              ? (totalPresences / totalSessions) * 100
              : 0.0;

          atRiskList.add(
            AtRiskStudent(
              student: student,
              consecutiveAbsences: recentSessions.length,
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

  Future<String?> _getClassName(String id) async {
    final c = await (_db.select(
      _db.classes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return c?.name;
  }

  /// Get aggregated weekly attendance percentage for the last 12 weeks
  Future<List<WeeklyStats>> getWeeklyAttendanceStats() async {
    // This is complex in pure Dart/Drift without raw SQL for date truncating.
    // simpler approach: Fetch all sessions/records for last 12 weeks and aggregate in memory.

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

    final statsMap = <int, _WeeklyAggregator>{}; // WeekIndex -> Data

    for (var session in sessions) {
      // Simple week grouping: milliseconds since epoch / week_ms
      final weekIndex =
          session.date.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24 * 7);

      final records =
          await (_db.select(_db.attendanceRecords)..where(
                (t) =>
                    t.sessionId.equals(session.id) & t.isDeleted.equals(false),
              ))
              .get();

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
  final String className;
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
