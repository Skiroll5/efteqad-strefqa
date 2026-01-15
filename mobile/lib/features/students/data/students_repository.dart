import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class StudentsRepository {
  final AppDatabase _db;

  StudentsRepository(this._db);

  Stream<List<Student>> watchStudentsByClass(String classId) {
    return (_db.select(_db.students)
          ..where((t) => t.classId.equals(classId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  Stream<Student?> watchStudent(String id) {
    return (_db.select(
      _db.students,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<void> addStudent(StudentsCompanion student) async {
    await _db.transaction(() async {
      await _db.into(_db.students).insert(student);

      // Serialize payload
      final payload = {
        'id': student.id.value,
        'name': student.name.value,
        'phone': student.phone.value,
        'classId': student.classId.value,
        'address': student.address.value,
        'birthdate': student.birthdate.value?.toIso8601String(),
        'createdAt': student.createdAt.value.toIso8601String(),
        'updatedAt': student.updatedAt.value.toIso8601String(),
        'isDeleted': false,
      };

      print('Repo: Inserting SyncQueue item for Student ${student.id.value}');

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              uuid: Value(const Uuid().v4()),
              entityType: const Value('STUDENT'),
              entityId: student.id,
              operation: const Value('CREATE'),
              payload: Value(jsonEncode(payload)),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  Future<void> updateStudent(Student student) async {
    await _db.transaction(() async {
      await _db.update(_db.students).replace(student);

      final payload = {
        'id': student.id,
        'name': student.name,
        'phone': student.phone,
        'classId': student.classId,
        'address': student.address,
        'birthdate': student.birthdate?.toIso8601String(),
        'createdAt': student.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isDeleted': student.isDeleted,
      };

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              uuid: Value(const Uuid().v4()),
              entityType: const Value('STUDENT'),
              entityId: Value(student.id),
              operation: const Value('UPDATE'),
              payload: Value(jsonEncode(payload)),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  Future<void> deleteStudent(String id) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      await (_db.update(_db.students)..where((t) => t.id.equals(id))).write(
        StudentsCompanion(isDeleted: const Value(true), deletedAt: Value(now)),
      );

      final payload = {
        'id': id,
        'isDeleted': true,
        'deletedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              uuid: Value(const Uuid().v4()),
              entityType: const Value('STUDENT'),
              entityId: Value(id),
              operation: const Value('DELETE'),
              payload: Value(jsonEncode(payload)),
              createdAt: Value(now),
            ),
          );
    });
  }
}
