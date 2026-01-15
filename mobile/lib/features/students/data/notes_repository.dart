import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class NotesRepository {
  final AppDatabase _db;

  NotesRepository(this._db);

  Future<void> addNote(
    String studentId,
    String content,
    String authorId,
  ) async {
    final id = const Uuid().v4();
    await _db.transaction(() async {
      await _db
          .into(_db.notes)
          .insert(
            NotesCompanion(
              id: Value(id),
              studentId: Value(studentId),
              content: Value(content),
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
              entityType: const Value('NOTE'),
              entityId: Value(id),
              operation: const Value('CREATE'),
              payload: Value(
                jsonEncode({
                  'studentId': studentId,
                  'content': content,
                  'authorId': authorId,
                  'createdAt': DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                }),
              ),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  Stream<List<Note>> watchNotesForStudent(String studentId) {
    return (_db.select(_db.notes)
          ..where((t) => t.studentId.equals(studentId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }
}
