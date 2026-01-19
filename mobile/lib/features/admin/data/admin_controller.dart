import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_repository.dart';
import '../../classes/data/classes_controller.dart';

/// Provider for all users (admin view)
final allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchAllUsers();
});

/// Provider for pending users awaiting activation
final pendingUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchPendingUsers();
});

/// Provider for aborted activation users
final abortedUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchAbortedUsers();
});

/// Provider for all classes (admin view)
final adminClassesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final classes = await repo.fetchClasses();
  final order = await ref.watch(classOrderProvider.future);

  if (order.isEmpty) return classes;

  classes.sort((a, b) {
    final indexA = order.indexOf(a['id']);
    final indexB = order.indexOf(b['id']);

    if (indexA == -1 && indexB == -1) {
      return (a['name'] as String).compareTo(b['name'] as String);
    }
    if (indexA == -1) return 1;
    if (indexB == -1) return -1;
    return indexA.compareTo(indexB);
  });

  return classes;
});

/// Provider for class managers of a specific class
final classManagersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      classId,
    ) async {
      final repo = ref.watch(adminRepositoryProvider);
      return repo.getClassManagers(classId);
    });

/// Controller for admin actions
class AdminController extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final Ref _ref;

  AdminController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  /// Activate a pending user
  Future<bool> activateUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.activateUser(userId);
      // Invalidate providers to refresh data
      _ref.invalidate(pendingUsersProvider);
      _ref.invalidate(allUsersProvider);
      _ref.invalidate(abortedUsersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Abort a pending user's activation (deny)
  Future<bool> abortActivation(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.abortActivation(userId);
      _ref.invalidate(pendingUsersProvider);
      _ref.invalidate(allUsersProvider);
      _ref.invalidate(abortedUsersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Enable a user
  Future<bool> enableUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.enableUser(userId);
      _ref.invalidate(allUsersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Disable a user
  Future<bool> disableUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.disableUser(userId);
      _ref.invalidate(allUsersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete a user (soft delete)
  Future<bool> deleteUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteUser(userId);
      _ref.invalidate(allUsersProvider);
      _ref.invalidate(pendingUsersProvider);
      _ref.invalidate(abortedUsersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Assign a class manager
  Future<bool> assignClassManager(String classId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.assignClassManager(classId, userId);
      _ref.invalidate(classManagersProvider(classId));
      _ref.invalidate(adminClassesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Remove a class manager
  Future<bool> removeClassManager(String classId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeClassManager(classId, userId);
      _ref.invalidate(classManagersProvider(classId));
      _ref.invalidate(adminClassesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Create a new class
  Future<bool> createClass(String name, String grade) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createClass(name, grade);
      _ref.invalidate(adminClassesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final adminControllerProvider =
    StateNotifierProvider<AdminController, AsyncValue<void>>((ref) {
      return AdminController(ref.watch(adminRepositoryProvider), ref);
    });
