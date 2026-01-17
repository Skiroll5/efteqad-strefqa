import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class NoteWithAuthor {
  final Note note;
  final String? authorName;

  NoteWithAuthor(this.note, this.authorName);
}

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
              authorId: Value(authorId),
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

  Future<void> updateNote(String noteId, String content) async {
    await _db.transaction(() async {
      // Fetch existing note to get foreign keys for sync payload
      final existingNote = await (_db.select(
        _db.notes,
      )..where((t) => t.id.equals(noteId))).getSingle();

      await (_db.update(_db.notes)..where((t) => t.id.equals(noteId))).write(
        NotesCompanion(
          content: Value(content),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              uuid: Value(const Uuid().v4()),
              entityType: const Value('NOTE'),
              entityId: Value(noteId),
              operation: const Value('UPDATE'),
              payload: Value(
                jsonEncode({
                  'content': content,
                  'studentId': existingNote.studentId,
                  'authorId': existingNote.authorId,
                  'updatedAt': DateTime.now().toIso8601String(),
                }),
              ),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((t) => t.id.equals(noteId))).write(
        NotesCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await _db
          .into(_db.syncQueue)
          .insert(
            SyncQueueCompanion(
              uuid: Value(const Uuid().v4()),
              entityType: const Value('NOTE'),
              entityId: Value(noteId),
              operation: const Value('DELETE'),
              payload: Value(
                jsonEncode({
                  'isDeleted': true,
                  'deletedAt': DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                }),
              ),
              createdAt: Value(DateTime.now()),
            ),
          );
    });
  }

  Stream<List<NoteWithAuthor>> watchNotesForStudent(String studentId) {
    final query =
        _db.select(_db.notes).join([
            leftOuterJoin(
              _db.users,
              _db.users.id.equalsExp(_db.notes.authorId),
            ),
          ])
          ..where(_db.notes.studentId.equals(studentId))
          ..where(_db.notes.isDeleted.equals(false))
          ..orderBy([
            OrderingTerm(
              expression: _db.notes.createdAt,
              mode: OrderingMode.desc,
            ),
          ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final note = row.readTable(_db.notes);
        final user = row.readTableOrNull(_db.users);
        return NoteWithAuthor(note, user?.name);
      }).toList();
    });
  }
}
