import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

import 'classes_repository.dart';

final classesRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ClassesRepository(db);
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
}
