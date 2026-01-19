import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../auth/data/auth_controller.dart';

import 'notes_repository.dart';

final notesRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return NotesRepository(db);
});

final studentNotesProvider =
    StreamProvider.family<List<NoteWithAuthor>, String>((ref, studentId) {
      final repo = ref.watch(notesRepositoryProvider);
      return repo.watchNotesForStudent(studentId);
    });

final notesControllerProvider =
    StateNotifierProvider<NotesController, AsyncValue<void>>((ref) {
      return NotesController(ref, ref.watch(notesRepositoryProvider));
    });

class NotesController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final NotesRepository _repo;

  NotesController(this._ref, this._repo) : super(const AsyncData(null));

  Future<void> addNote(String studentId, String content) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      await _repo.addNote(studentId, content, user.id, user.name);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateNote(String noteId, String content) async {
    state = const AsyncLoading();
    try {
      await _repo.updateNote(noteId, content);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteNote(String noteId) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteNote(noteId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
