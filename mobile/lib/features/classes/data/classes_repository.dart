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
}
