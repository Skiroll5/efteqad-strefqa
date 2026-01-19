import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../auth/data/auth_controller.dart';

import 'classes_repository.dart';

final classesRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ClassesRepository(db, Dio());
});

/// Stream of all classes (for admins)
final allClassesStreamProvider = StreamProvider<List<ClassesData>>((ref) {
  final repository = ref.watch(classesRepositoryProvider);
  return repository.watchAllClasses();
});

/// Stream of classes for current user (based on role)
/// - Admin: sees all classes
/// - Servant: sees only assigned classes via ClassManagers
final userClassesStreamProvider = StreamProvider<List<ClassesData>>((ref) {
  final repository = ref.watch(classesRepositoryProvider);
  final authState = ref.watch(authControllerProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        // Not logged in, return empty stream
        return Stream.value([]);
      }

      if (user.role == 'ADMIN') {
        // Admin sees all classes
        return repository.watchAllClasses();
      } else {
        // Servant sees only assigned classes
        return repository.watchClassesForUser(user.id);
      }
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Legacy provider for backwards compatibility
final classesStreamProvider = StreamProvider<List<ClassesData>>((ref) {
  final repository = ref.watch(classesRepositoryProvider);
  return repository.watchAllClasses();
});

final classesControllerProvider = Provider((ref) => ClassesController(ref));

class ClassesController {
  final Ref _ref;

  ClassesController(this._ref);

  Future<void> addClass(String name, String? grade) async {
    final repository = _ref.read(classesRepositoryProvider);
    await repository.addClass(name, grade);
  }

  Future<void> updateClass(String id, String newName) async {
    final repository = _ref.read(classesRepositoryProvider);
    await repository.updateClass(id, newName);
  }

  Future<void> deleteClass(String id) async {
    final repository = _ref.read(classesRepositoryProvider);
    await repository.deleteClass(id);
  }

  /// Get managers for a specific class
  Future<List<User>> getManagersForClass(String classId) async {
    final repository = _ref.read(classesRepositoryProvider);
    return repository.getManagersForClass(classId);
  }
}
