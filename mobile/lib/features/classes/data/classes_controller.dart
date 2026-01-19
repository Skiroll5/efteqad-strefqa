import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../auth/data/auth_controller.dart';

import 'classes_repository.dart';
import 'class_order_service.dart';

import '../../sync/data/sync_service.dart';

final classesRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return ClassesRepository(db, Dio(), syncService);
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

      // Simplify: All users see all classes locally (since DB is restricted to user's scope by sync)
      return repository.watchAllClasses();
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

final classOrderProvider = FutureProvider<List<String>>((ref) {
  final service = ref.watch(classOrderServiceProvider);
  return service.getClassOrder();
});

final orderedUserClassesProvider = Provider<AsyncValue<List<ClassesData>>>((
  ref,
) {
  final classesAsync = ref.watch(userClassesStreamProvider);
  final orderAsync = ref.watch(classOrderProvider);

  // If classes are loading, return loading
  if (classesAsync.isLoading || orderAsync.isLoading) {
    return const AsyncLoading();
  }

  // If error, return error
  if (classesAsync.hasError) {
    return AsyncError(classesAsync.error!, classesAsync.stackTrace!);
  }

  final classes = classesAsync.value ?? [];
  final order = orderAsync.value ?? [];

  if (order.isEmpty) {
    return AsyncData(classes);
  }

  final sorted = [...classes];
  sorted.sort((a, b) {
    final indexA = order.indexOf(a.id);
    final indexB = order.indexOf(b.id);

    if (indexA == -1 && indexB == -1) {
      return a.name.compareTo(b.name);
    }
    if (indexA == -1) {
      return 1;
    } // Unordered go to end
    if (indexB == -1) {
      return -1;
    }
    return indexA.compareTo(indexB);
  });

  return AsyncData(sorted);
});

class ClassesController {
  final Ref _ref;

  ClassesController(this._ref);

  Future<void> updateClassOrder(List<String> newOrder) async {
    final service = _ref.read(classOrderServiceProvider);
    await service.saveClassOrder(newOrder);
    _ref.invalidate(classOrderProvider);
  }

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
  // getManagersForClass removed - using de-normalized data
}
