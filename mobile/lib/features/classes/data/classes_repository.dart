import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/config/api_config.dart';

class ClassesRepository {
  final AppDatabase _db;
  final Dio _dio;
  final String _baseUrl = ApiConfig.baseUrl;

  ClassesRepository(this._db, this._dio);

  /// Watch all classes (for admins)
  Stream<List<ClassesData>> watchAllClasses() {
    return (_db.select(_db.classes)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// Watch classes assigned to a specific user via ClassManagers
  Stream<List<ClassesData>> watchClassesForUser(String userId) {
    // Join classes with classManagers to get only assigned classes
    final query =
        _db.select(_db.classes).join([
            innerJoin(
              _db.classManagers,
              _db.classManagers.classId.equalsExp(_db.classes.id),
            ),
          ])
          ..where(_db.classes.isDeleted.equals(false))
          ..where(_db.classManagers.userId.equals(userId))
          ..orderBy([OrderingTerm(expression: _db.classes.name)]);

    return query.watch().map((rows) {
      return rows.map((row) => row.readTable(_db.classes)).toList();
    });
  }

  /// Get all managers for a specific class
  Future<List<User>> getManagersForClass(String classId) async {
    final query =
        _db.select(_db.users).join([
            innerJoin(
              _db.classManagers,
              _db.classManagers.userId.equalsExp(_db.users.id),
            ),
          ])
          ..where(_db.classManagers.classId.equals(classId))
          ..where(_db.users.isDeleted.equals(false));

    final rows = await query.get();
    return rows.map((row) => row.readTable(_db.users)).toList();
  }

  Future<void> addClass(String name, String? grade) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    // Optimistic Update Payload (Local DB)
    final localEntity = ClassesCompanion(
      id: Value(id),
      name: Value(name),
      grade: Value(grade),
      isDeleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    // Prepare API Payload
    final apiPayload = {
      'id': id,
      'name': name,
      'grade': grade,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    try {
      // 1. Try Online First
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      await _dio.post(
        '$_baseUrl/classes',
        data: apiPayload,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(
            seconds: 5,
          ), // Short timeout for interactivity
        ),
      );

      // 2. Success: Save to Local DB (As synced)
      await _db.into(_db.classes).insert(localEntity);
      // print('ClassesRepo: Online Add Success');
    } catch (e) {
      // 3. Failure: Save to Local DB + Queue
      // print('ClassesRepo: Online Add Failed ($e). Fallback to Queue.');

      await _db.transaction(() async {
        await _db.into(_db.classes).insert(localEntity);

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
                    'createdAt': now.toIso8601String(),
                    'updatedAt': now.toIso8601String(),
                  }),
                ), // Payload for queue might be different if queue processor expects body only?
                // Existing queue processor sends `payload` as body.
                // Wait, existing SyncService re-wraps it.
                // Checking SyncService.pushChanges:
                // 'payload': jsonDecode(item.payload)
                // And sends { changes: [ ... ] }
                // The API endpoint `/classes` expects a SINGLE object?
                // The offline queue uses `/sync` endpoint which processes a batch.
                // The online call uses `/classes` endpoint (standard REST).
                // So we must ensure API payload for /classes matches.
                createdAt: Value(now),
              ),
            );
      });
    }
  }

  Future<void> updateClass(String id, String newName) async {
    final now = DateTime.now();

    // Optimistic Entity
    final localEntity = ClassesCompanion(
      name: Value(newName),
      updatedAt: Value(now),
    );

    // API Payload
    final apiPayload = {'name': newName};

    try {
      // 1. Try Online
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      await _dio.put(
        '$_baseUrl/classes/$id',
        data: apiPayload,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      // 2. Success: Update Local
      await (_db.update(
        _db.classes,
      )..where((t) => t.id.equals(id))).write(localEntity);
    } catch (e) {
      // 3. Fallback
      // print('ClassesRepo: Online Update Failed ($e). Fallback to Queue.');
      await _db.transaction(() async {
        await (_db.update(
          _db.classes,
        )..where((t) => t.id.equals(id))).write(localEntity);

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
  }

  Future<void> deleteClass(String id) async {
    final now = DateTime.now();

    try {
      // 1. Try Online
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      await _dio.delete(
        '$_baseUrl/classes/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      // 2. Success: Local Soft Delete
      await _localDelete(id, now);
    } catch (e) {
      // 3. Fallback
      // print('ClassesRepo: Online Delete Failed ($e). Fallback to Queue.');
      await _db.transaction(() async {
        await _localDelete(id, now);

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

  Future<void> _localDelete(String id, DateTime now) async {
    // Soft delete the class
    await (_db.update(_db.classes)..where((t) => t.id.equals(id))).write(
      ClassesCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    // Soft delete all students in this class
    await (_db.update(_db.students)..where((t) => t.classId.equals(id))).write(
      StudentsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  // Exposed for SyncService to call when pulling data
  Future<void> upsertClassFromSync(Map<String, dynamic> data) async {
    final entity = ClassesCompanion(
      id: Value(data['id']),
      name: Value(data['name']),
      grade: Value(data['grade']),
      createdAt: Value(DateTime.parse(data['createdAt'])),
      updatedAt: Value(DateTime.parse(data['updatedAt'])),
      isDeleted: Value(data['isDeleted'] ?? false),
      deletedAt: Value(
        data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      ),
    );
    await _db.into(_db.classes).insertOnConflictUpdate(entity);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
