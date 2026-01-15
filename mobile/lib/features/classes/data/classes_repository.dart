import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class ClassesRepository {
  final AppDatabase _db;

  ClassesRepository(this._db);

  Stream<List<ClassesData>> watchAllClasses() {
    return (_db.select(_db.classes)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  Future<void> addClass(String name, String? grade) async {
    final id = const Uuid().v4();
    await _db.transaction(() async {
      await _db
          .into(_db.classes)
          .insert(
            ClassesCompanion(
              id: Value(id),
              name: Value(name),
              grade: Value(grade),
              isDeleted: const Value(false),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              uuid: Value(const Uuid().v4()),
              entityType: const Value('CLASS'),
              entityId: Value(id),
              operation: const Value('CREATE'),
              payload: Value(
                jsonEncode({
                  'name': name,
                  'grade': grade,
                  'createdAt': DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                }),
              ),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  Future<void> updateClass(String id, String newName) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.classes)..where((t) => t.id.equals(id))).write(
        ClassesCompanion(name: Value(newName), updatedAt: Value(now)),
      );

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              uuid: Value(const Uuid().v4()),
              entityType: const Value('CLASS'),
              entityId: Value(id),
              operation: const Value('UPDATE'),
              payload: Value(
                jsonEncode({
                  'id': id,
                  'name': newName,
                  'updatedAt': now.toIso8601String(),
                }),
              ),
              createdAt: Value(now),
            ),
          );
    });
  }

  Future<void> deleteClass(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      // Soft delete the class
      await (_db.update(_db.classes)..where((t) => t.id.equals(id))).write(
        ClassesCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Soft delete all students in this class
      await (_db.update(
        _db.students,
      )..where((t) => t.classId.equals(id))).write(
        StudentsCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              uuid: Value(const Uuid().v4()),
              entityType: const Value('CLASS'),
              entityId: Value(id),
              operation: const Value('DELETE'),
              payload: Value(
                jsonEncode({'id': id, 'deletedAt': now.toIso8601String()}),
              ),
              createdAt: Value(now),
            ),
          );
    });
  }
}
