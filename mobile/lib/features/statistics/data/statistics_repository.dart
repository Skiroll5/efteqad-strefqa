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

      // Get last [threshold] sessions for this class
      final sessions =
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

      // If not enough sessions to judge, skip (or assume mostly at risk if 0 sessions? No, can't judge)
      if (sessions.isEmpty) continue;

      final sessionIds = sessions.map((s) => s.id).toList();

      // For the students in this class, check their attendance in these sessions
      for (var student in classStudents) {
        // Count how many times they were PRESENT in these specific sessions
        final presentCountQuery = _db.select(_db.attendanceRecords)
          ..where(
            (t) =>
                t.studentId.equals(student.id) &
                t.sessionId.isIn(sessionIds) &
                t.status.equals('PRESENT') &
                t.isDeleted.equals(false),
          );

        final presentRecords = await presentCountQuery.get();

        // If they were NOT present in ANY of the last [threshold] sessions
        // (i.e. presentCount == 0), they are at risk.
        // Even if there are fewer than [threshold] sessions total (e.g. only 2 sessions exist),
        // if they missed all of them, they are effectively at risk for the duration of the class so far.
        // But strict "consecutive" usually implies the full window.
        // Let's go with: if they have 0 present records in the fetched sessions.

        if (presentRecords.isEmpty) {
          atRiskList.add(
            AtRiskStudent(
              student: student,
              consecutiveAbsences: sessions.length, // Or just 'threshold'+
              className: (await _getClassName(classId)) ?? 'Unknown Class',
              phoneNumber: student.phone,
            ),
          );
        }
      }
    }

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

  AtRiskStudent({
    required this.student,
    required this.className,
    required this.consecutiveAbsences,
    this.phoneNumber,
  });
}

class WeeklyStats {
  final DateTime weekStart;
  final double attendanceRate;

  WeeklyStats({required this.weekStart, required this.attendanceRate});
}
