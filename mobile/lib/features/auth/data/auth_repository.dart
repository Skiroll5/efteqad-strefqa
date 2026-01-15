import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/api_config.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(Dio()));

class AuthRepository {
  final Dio _dio;
  // TODO: Move base URL to config
  final String _baseUrl = ApiConfig.baseUrl;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data; // { token, user }
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Registration failed';
    }
  }
}
