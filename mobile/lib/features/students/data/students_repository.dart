import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/config/api_config.dart';

class StudentsRepository {
  final AppDatabase _db;
  final Dio _dio;
  final String _baseUrl = ApiConfig.baseUrl;

  StudentsRepository(this._db, this._dio);

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
    // Check required values
    if (!student.id.present || !student.name.present) {
      throw Exception('ID and Name are required');
    }

    final now = DateTime.now();
    // Ensure timestamps are set if not present
    final localEntity = student.copyWith(
      createdAt: student.createdAt.present ? student.createdAt : Value(now),
      updatedAt: student.updatedAt.present ? student.updatedAt : Value(now),
      isDeleted: student.isDeleted.present
          ? student.isDeleted
          : const Value(false),
    );

    // Prepare API Payload
    final apiPayload = {
      'id': student.id.value,
      'name': student.name.value,
      'phone': student.phone.value,
      'classId': student.classId.value,
      'address': student.address.value,
      'birthdate': student.birthdate.value?.toIso8601String(),
      'createdAt': localEntity.createdAt.value.toIso8601String(),
      'updatedAt': localEntity.updatedAt.value.toIso8601String(),
      'isDeleted': false,
    };

    try {
      // 1. Try Online First
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      await _dio.post(
        '$_baseUrl/students',
        data: apiPayload,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      // 2. Success: Save to Local DB
      await _db.into(_db.students).insert(localEntity);
      print('StudentsRepo: Online Add Success');
    } catch (e) {
      // 3. Fallback: Save to Local + Queue
      print('StudentsRepo: Online Add Failed ($e). Fallback to Queue.');

      await _db.transaction(() async {
        await _db.into(_db.students).insert(localEntity);

        await _db
            .into(_db.syncQueue)
            .insert(
              SyncQueueCompanion(
                uuid: Value(const Uuid().v4()),
                entityType: const Value('STUDENT'),
                entityId: student.id,
                operation: const Value('CREATE'),
                payload: Value(jsonEncode(apiPayload)),
                createdAt: Value(now),
              ),
            );
      });
    }
  }

  Future<void> updateStudent(Student student) async {
    final now = DateTime.now();

    // Optimistic Update
    final localEntity = student.copyWith(updatedAt: now);

    // API Payload
    final apiPayload = {
      'id': student.id,
      'name': student.name,
      'phone': student.phone,
      'classId': student.classId,
      'address': student.address,
      'birthdate': student.birthdate?.toIso8601String(),
      'createdAt': student.createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'isDeleted': student.isDeleted,
    };

    try {
      // 1. Try Online
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      await _dio.put(
        '$_baseUrl/students/${student.id}',
        data: apiPayload,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      // 2. Success: Update Local
      await _db.update(_db.students).replace(localEntity);
    } catch (e) {
      // 3. Fallback
      print('StudentsRepo: Online Update Failed ($e). Fallback to Queue.');

      await _db.transaction(() async {
        await _db.update(_db.students).replace(localEntity);

        await _db
            .into(_db.syncQueue)
            .insert(
              SyncQueueCompanion(
                uuid: Value(const Uuid().v4()),
                entityType: const Value('STUDENT'),
                entityId: Value(student.id),
                operation: const Value('UPDATE'),
                payload: Value(jsonEncode(apiPayload)),
                createdAt: Value(now),
              ),
            );
      });
    }
  }

  Future<void> deleteStudent(String id) async {
    final now = DateTime.now();

    try {
      // 1. Try Online
      final token = await _getToken();
      if (token == null) throw Exception('No token');

      await _dio.delete(
        '$_baseUrl/students/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      // 2. Success: Local Delete
      await (_db.update(_db.students)..where((t) => t.id.equals(id))).write(
        StudentsCompanion(isDeleted: const Value(true), deletedAt: Value(now)),
      );
    } catch (e) {
      // 3. Fallback
      print('StudentsRepo: Online Delete Failed ($e). Fallback to Queue.');

      await _db.transaction(() async {
        await (_db.update(_db.students)..where((t) => t.id.equals(id))).write(
          StudentsCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(now),
          ),
        );

        await _db
            .into(_db.syncQueue)
            .insert(
              SyncQueueCompanion(
                uuid: Value(const Uuid().v4()),
                entityType: const Value('STUDENT'),
                entityId: Value(id),
                operation: const Value('DELETE'),
                payload: Value(
                  jsonEncode({
                    'id': id,
                    'isDeleted': true,
                    'deletedAt': now.toIso8601String(),
                    'updatedAt': now.toIso8601String(),
                  }),
                ),
                createdAt: Value(now),
              ),
            );
      });
    }
  }

  Future<void> upsertStudentFromSync(Map<String, dynamic> data) async {
    final entity = StudentsCompanion(
      id: Value(data['id']),
      name: Value(data['name']),
      phone: Value(data['phone']),
      address: Value(data['address']),
      birthdate: Value(
        data['birthdate'] != null ? DateTime.parse(data['birthdate']) : null,
      ),
      classId: Value(data['classId']),
      createdAt: Value(DateTime.parse(data['createdAt'])),
      updatedAt: Value(DateTime.parse(data['updatedAt'])),
      isDeleted: Value(data['isDeleted'] ?? false),
      deletedAt: Value(
        data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      ),
    );
    await _db.into(_db.students).insertOnConflictUpdate(entity);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
