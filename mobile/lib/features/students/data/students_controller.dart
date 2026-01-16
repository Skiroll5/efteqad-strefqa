import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../auth/data/auth_controller.dart';
import 'students_repository.dart';

final uuidProvider = Provider((ref) => const Uuid());

final studentsRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StudentsRepository(db, Dio());
});

final selectedClassIdProvider = StateProvider<String?>((ref) => null);

final classStudentsProvider = StreamProvider.autoDispose<List<Student>>((ref) {
  final user = ref.watch(authControllerProvider).asData?.value;
  if (user == null) return Stream.value([]);

  String? targetClassId;
  if (user.role == 'ADMIN') {
    targetClassId = ref.watch(selectedClassIdProvider);
  } else {
    targetClassId = user.classId;
  }

  if (targetClassId == null) return Stream.value([]);

  final repo = ref.watch(studentsRepositoryProvider);
  return repo.watchStudentsByClass(targetClassId);
});

final studentProvider = StreamProvider.autoDispose.family<Student?, String>((
  ref,
  id,
) {
  final repo = ref.watch(studentsRepositoryProvider);
  return repo.watchStudent(id);
});

final studentsControllerProvider = Provider((ref) {
  return StudentsController(ref);
});

class StudentsController {
  final Ref _ref;

  StudentsController(this._ref);

  Future<void> addStudent({
    required String name,
    required String phone,
    required String? classId,
    String? address,
    DateTime? birthdate,
  }) async {
    final repo = _ref.read(studentsRepositoryProvider);
    final uuid = _ref.read(uuidProvider);

    print('Controller: Adding student $name to class $classId');
    try {
      await repo.addStudent(
        StudentsCompanion(
          id: Value(uuid.v4()),
          name: Value(name),
          phone: Value(phone),
          classId: Value(classId),
          address: Value(address),
          birthdate: Value(birthdate),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      print('Controller: Add student done');
    } catch (e) {
      print('Controller Error: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(Student student) async {
    final repo = _ref.read(studentsRepositoryProvider);
    try {
      await repo.updateStudent(student);
    } catch (e) {
      print('Controller Error: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    final repo = _ref.read(studentsRepositoryProvider);
    try {
      await repo.deleteStudent(id);
    } catch (e) {
      print('Controller Error: $e');
      rethrow;
    }
  }
}
