import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/config/api_config.dart';

import '../../sync/data/sync_service.dart';

class ClassesRepository {
  final AppDatabase _db;
  final Dio _dio;
  final SyncService _syncService;
  final String _baseUrl = ApiConfig.baseUrl;

  ClassesRepository(this._db, this._dio, this._syncService);

  /// Watch all classes (for admins)
  Stream<List<ClassesData>> watchAllClasses() {
    return (_db.select(_db.classes)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  // Formerly watchClassesForUser - now handled by permissions logic + selective sync

  // Formerly getManagersForClass - now de-normalized in Classes table

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

    await _syncService.trySyncFirst(
      entityType: 'CLASS',
      entityId: id,
      operation: 'CREATE',
      payload: apiPayload,
      performOnline: () async {
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
      },
      performLocal: () async {
        await _db.into(_db.classes).insert(localEntity);
      },
    );
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

    await _syncService.trySyncFirst(
      entityType: 'CLASS',
      entityId: id,
      operation: 'UPDATE',
      payload: {...apiPayload, 'id': id, 'updatedAt': now.toIso8601String()},
      performOnline: () async {
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
      },
      performLocal: () async {
        await (_db.update(
          _db.classes,
        )..where((t) => t.id.equals(id))).write(localEntity);
      },
    );
  }

  Future<void> deleteClass(String id) async {
    final now = DateTime.now();

    await _syncService.trySyncFirst(
      entityType: 'CLASS',
      entityId: id,
      operation: 'DELETE',
      payload: {'id': id, 'deletedAt': now.toIso8601String()},
      performOnline: () async {
        final token = await _getToken();
        if (token == null) throw Exception('No token');

        await _dio.delete(
          '$_baseUrl/classes/$id',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            sendTimeout: const Duration(seconds: 5),
          ),
        );
      },
      performLocal: () async {
        await _localDelete(id, now);
      },
    );
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

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
