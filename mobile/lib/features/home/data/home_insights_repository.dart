import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

final homeInsightsRepositoryProvider = Provider<HomeInsightsRepository>((ref) {
  return HomeInsightsRepository(ref.read(appDatabaseProvider));
});

final classesLatestSessionsProvider = FutureProvider<List<ClassSessionStatus>>((
  ref,
) async {
  final repo = ref.read(homeInsightsRepositoryProvider);
  return repo.getClassesLatestSessions();
});

class HomeInsightsRepository {
  final AppDatabase _db;

  HomeInsightsRepository(this._db);

  Future<List<ClassSessionStatus>> getClassesLatestSessions() async {
    final result = <ClassSessionStatus>[];

    // 1. Get all active classes
    final classes = await (_db.select(
      _db.classes,
    )..where((t) => t.isDeleted.equals(false))).get();

    for (var cls in classes) {
      // 2. Get latest session for this class
      final latestSession =
          await (_db.select(_db.attendanceSessions)
                ..where(
                  (t) => t.classId.equals(cls.id) & t.isDeleted.equals(false),
                )
                ..orderBy([
                  (t) =>
                      OrderingTerm(expression: t.date, mode: OrderingMode.desc),
                ])
                ..limit(1))
              .getSingleOrNull();

      if (latestSession == null) {
        // No session yet
        result.add(
          ClassSessionStatus(
            classId: cls.id,
            className: cls.name,
            hasSession: false,
          ),
        );
        continue;
      }

      // 3. Get attendance stats for this session
      final records =
          await (_db.select(_db.attendanceRecords)..where(
                (t) =>
                    t.sessionId.equals(latestSession.id) &
                    t.isDeleted.equals(false),
              ))
              .get();

      final total = records.length;
      final present = records.where((r) => r.status == 'PRESENT').length;
      final rate = total > 0 ? present / total : 0.0;

      result.add(
        ClassSessionStatus(
          classId: cls.id,
          className: cls.name,
          hasSession: true,
          lastSessionDate: latestSession.date,
          attendanceRate: rate,
          totalStudents: total,
          presentCount: present,
          session: latestSession,
        ),
      );
    }

    // Sort by date descending (most recent first), sessions first
    result.sort((a, b) {
      if (!a.hasSession && !b.hasSession) return 0;
      if (!a.hasSession) return 1;
      if (!b.hasSession) return -1;
      return b.lastSessionDate!.compareTo(a.lastSessionDate!);
    });

    return result;
  }
}

class ClassSessionStatus {
  final String classId;
  final String className;
  final bool hasSession;
  final DateTime? lastSessionDate;
  final double attendanceRate;
  final int totalStudents;
  final int presentCount;
  final AttendanceSession? session;

  ClassSessionStatus({
    required this.classId,
    required this.className,
    required this.hasSession,
    this.lastSessionDate,
    this.attendanceRate = 0.0,
    this.totalStudents = 0,
    this.presentCount = 0,
    this.session,
  });
}
