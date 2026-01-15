import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import 'attendance_repository.dart';
import 'attendance_session_repository.dart';
import '../../students/data/students_controller.dart';

// --- Providers ---

final attendanceRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AttendanceRepository(db);
});

// Watch sessions for the currently selected class
final attendanceSessionsProvider = StreamProvider<List<AttendanceSession>>((
  ref,
) {
  final selectedClassId = ref.watch(selectedClassIdProvider);
  if (selectedClassId == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(attendanceSessionRepositoryProvider);
  return repo.watchSessionsForClass(selectedClassId);
});

// Watch records for a specific session
final sessionRecordsProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, sessionId) {
      final repo = ref.watch(attendanceRepositoryProvider);
      return repo.watchRecordsForSession(sessionId);
    });

// --- Controller ---

final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AsyncValue<void>>((ref) {
      return AttendanceController(
        ref.watch(attendanceSessionRepositoryProvider),
        ref.watch(attendanceRepositoryProvider),
      );
    });

class AttendanceController extends StateNotifier<AsyncValue<void>> {
  final AttendanceSessionRepository _sessionRepo;
  final AttendanceRepository _recordRepo;

  AttendanceController(this._sessionRepo, this._recordRepo)
    : super(const AsyncData(null));

  // Create a new session and save attendance
  Future<AttendanceSession?> createSessionWithAttendance({
    required String classId,
    required DateTime date,
    String? note,
    required Map<String, bool> attendance,
  }) async {
    state = const AsyncLoading();
    try {
      // 1. Create the session
      final session = await _sessionRepo.createSession(
        classId: classId,
        date: date,
        note: note,
      );

      // 2. Save attendance records for that session
      await _recordRepo.saveAttendanceBatch(
        sessionId: session.id,
        attendance: attendance,
      );

      state = const AsyncData(null);
      return session;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  // Update session note/date
  Future<void> updateSession(AttendanceSession session) async {
    state = const AsyncLoading();
    try {
      await _sessionRepo.updateSession(session);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Delete a session (and its records)
  Future<void> deleteSession(String sessionId) async {
    state = const AsyncLoading();
    try {
      await _recordRepo.deleteRecordsForSession(sessionId);
      await _sessionRepo.deleteSession(sessionId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Update a single attendance record's status
  Future<void> updateRecordStatus(String recordId, String newStatus) async {
    state = const AsyncLoading();
    try {
      await _recordRepo.updateRecord(recordId, newStatus);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
