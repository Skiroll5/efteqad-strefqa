import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/database/app_database.dart';
import '../../classes/data/class_order_service.dart';
import '../../auth/domain/user_model.dart' as domain;

final homeInsightsRepositoryProvider = Provider<HomeInsightsRepository>((ref) {
  return HomeInsightsRepository(ref.read(appDatabaseProvider));
});

final classesLatestSessionsProvider = StreamProvider<List<ClassSessionStatus>>((
  ref,
) {
  final repo = ref.read(homeInsightsRepositoryProvider);
  final classOrderService = ref.read(classOrderServiceProvider);
  return repo.watchClassesLatestSessions(
    loadClassOrder: classOrderService.getClassOrder,
  );
});

class HomeInsightsRepository {
  final AppDatabase _db;

  HomeInsightsRepository(this._db);

  Future<List<ClassSessionStatus>> getClassesLatestSessions({
    List<String> classOrder = const [],
  }) async {
    final result = <ClassSessionStatus>[];

    // 1. Get all active classes
    final classes = await (_db.select(
      _db.classes,
    )..where((t) => t.isDeleted.equals(false))).get();

    if (classes.isEmpty) return [];

    final classIds = classes.map((c) => c.id).toList();

    // 2. Get latest session for each class efficiently
    // Optimized: Use a single custom query to fetch the latest session for all classes
    // This avoids N+1 queries.
    // Query logic:
    // SELECT s.* FROM attendance_sessions s
    // INNER JOIN (
    //   SELECT class_id, MAX(date) as max_date
    //   FROM attendance_sessions
    //   WHERE is_deleted = 0
    //   GROUP BY class_id
    // ) latest ON s.class_id = latest.class_id AND s.date = latest.max_date
    // WHERE s.is_deleted = 0 AND s.class_id IN (...)

    // Safety check for empty classIds to avoid SQL error
    if (classIds.isEmpty) return [];

    final sessionsQuery = _db.customSelect(
      'SELECT s.* FROM attendance_sessions s '
      'INNER JOIN ('
      '  SELECT class_id, MAX(date) as max_date '
      '  FROM attendance_sessions '
      '  WHERE is_deleted = 0 '
      '  GROUP BY class_id'
      ') latest ON s.class_id = latest.class_id AND s.date = latest.max_date '
      'WHERE s.is_deleted = 0 AND s.class_id IN (${classIds.map((_) => '?').join(', ')})',
      variables: classIds.map((id) => Variable.withString(id)).toList(),
      readsFrom: {_db.attendanceSessions},
    );

    final sessionsRows = await sessionsQuery.get();
    final latestSessions = sessionsRows
        .map((row) => _db.attendanceSessions.map(row.data))
        .toList();

    final sessionMap = {for (var s in latestSessions) s.classId: s};

    // 3. Get attendance stats for these sessions
    final sessionIds = latestSessions.map((s) => s.id).toList();

    List<AttendanceRecord> allRecords = [];
    if (sessionIds.isNotEmpty) {
      allRecords =
          await (_db.select(_db.attendanceRecords)..where(
                (t) => t.sessionId.isIn(sessionIds) & t.isDeleted.equals(false),
              ))
              .get();
    }

    final recordsMap = <String, List<AttendanceRecord>>{};
    for (var r in allRecords) {
      recordsMap.putIfAbsent(r.sessionId, () => []).add(r);
    }

    // 4. Build result in memory
    for (var cls in classes) {
      final latestSession = sessionMap[cls.id];

      if (latestSession == null) {
        result.add(
          ClassSessionStatus(
            classId: cls.id,
            className: cls.name,
            hasSession: false,
          ),
        );
        continue;
      }

      final records = recordsMap[latestSession.id] ?? [];
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

    // Sort by user-defined class order (if available)
    // Classes not in the order list go to the end, sorted by name
    if (classOrder.isNotEmpty) {
      result.sort((a, b) {
        final indexA = classOrder.indexOf(a.classId);
        final indexB = classOrder.indexOf(b.classId);

        // Both in order list - sort by order
        if (indexA >= 0 && indexB >= 0) {
          return indexA.compareTo(indexB);
        }
        // Only a is in order list - a comes first
        if (indexA >= 0) return -1;
        // Only b is in order list - b comes first
        if (indexB >= 0) return 1;
        // Neither in order list - sort by class name
        return a.className.compareTo(b.className);
      });
    } else {
      // No user-defined order - sort by date descending (most recent first)
      result.sort((a, b) {
        if (!a.hasSession && !b.hasSession) return 0;
        if (!a.hasSession) return 1;
        if (!b.hasSession) return -1;
        return b.lastSessionDate!.compareTo(a.lastSessionDate!);
      });
    }

    return result;
  }

  Stream<List<ClassSessionStatus>> watchClassesLatestSessions({
    required Future<List<String>> Function() loadClassOrder,
  }) {
    final changesStream = Rx.merge([
      _db.select(_db.classes).watch(),
      _db.select(_db.attendanceSessions).watch(),
      _db.select(_db.attendanceRecords).watch(),
    ]);

    return changesStream
        .debounceTime(const Duration(milliseconds: 300))
        .asyncMap((_) async {
          final classOrder = await loadClassOrder();
          return getClassesLatestSessions(classOrder: classOrder);
        });
  }

  Future<String> getStudentWhatsAppMessage(
    String studentId, {
    required domain.User user,
    required String defaultTemplate,
  }) async {
    // 1. Get Student for placeholders
    final student = await (_db.select(
      _db.students,
    )..where((t) => t.id.equals(studentId))).getSingleOrNull();

    if (student == null) return defaultTemplate;

    String message = defaultTemplate;

    // 2. Check custom preference for this student
    final pref =
        await (_db.select(_db.userStudentPreferences)..where(
              (t) => t.userId.equals(user.id) & t.studentId.equals(studentId),
            ))
            .getSingleOrNull();

    if (pref != null &&
        pref.customWhatsappMessage != null &&
        pref.customWhatsappMessage!.isNotEmpty) {
      message = pref.customWhatsappMessage!;
    }
    // 3. Check user's global template (if not null, use it even if empty to allow clearing)
    else if (user.whatsappTemplate != null) {
      message = user.whatsappTemplate!;
    }
    // 4. Fallback to passed defaultTemplate (already set)

    // 5. Replace placeholders
    if (message.isEmpty) return "";

    final firstName = student.name.split(' ').first;
    // Handle both old style {}, %, and new style [] placeholders
    message = message
        .replaceAll('{firstname}', firstName)
        .replaceAll('%firstname%', firstName)
        .replaceAll('[firstname]', firstName);
    message = message
        .replaceAll('{name}', student.name)
        .replaceAll('[name]', student.name);

    if (student.birthdate != null) {
      final now = DateTime.now();
      final birthdate = student.birthdate!;
      int age = (now.year - birthdate.year).toInt();
      if (now.month < birthdate.month ||
          (now.month == birthdate.month && now.day < birthdate.day)) {
        age--;
      }
      message = message
          .replaceAll('{age}', age.toString())
          .replaceAll('[age]', age.toString());
    } else {
      message = message.replaceAll('{age}', '').replaceAll('[age]', '');
    }

    return message;
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
