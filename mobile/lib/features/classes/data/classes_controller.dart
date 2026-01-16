import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

import 'classes_repository.dart';

final classesRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ClassesRepository(db, Dio());
});

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
}
