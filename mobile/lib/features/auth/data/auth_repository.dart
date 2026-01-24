import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/api_config.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(Dio()));

/// Error class to hold structured error information
class AuthError {
  final String message;
  final String code;

  AuthError(this.message, this.code);

  @override
  String toString() => message;
}

class AuthRepository {
  final Dio _dio;
  final String _baseUrl = ApiConfig.baseUrl;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {'identifier': identifier, 'password': password},
      );
      return response.data; // { token, user }
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Login failed';
      String code = 'UNKNOWN';

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        code = data['code'] ?? code;
      }
      throw AuthError(message, code);
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name, {
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          if (phone != null) 'phone': phone,
        },
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Registration failed';
      String code = 'UNKNOWN';

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        code = data['code'] ?? code;
      }
      throw AuthError(message, code);
    }
  }

  Future<void> forgotPassword(String identifier) async {
    try {
      await _dio.post(
        '$_baseUrl/auth/forgot-password',
        data: {'identifier': identifier},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Request failed';
      String code = 'UNKNOWN';

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        code = data['code'] ?? code;
      }
      throw AuthError(message, code);
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _dio.post(
        '$_baseUrl/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Reset failed';
      String code = 'UNKNOWN';

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        code = data['code'] ?? code;
      }
      throw AuthError(message, code);
    }
  }

  Future<void> verifyResetOtp(String otp) async {
    try {
      await _dio.post('$_baseUrl/auth/verify-reset-otp', data: {'token': otp});
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Invalid OTP';
      String code = 'UNKNOWN';

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        code = data['code'] ?? code;
      }
      throw AuthError(message, code);
    }
  }

  Future<void> confirmEmail(String token) async {
    try {
      await _dio.post('$_baseUrl/auth/confirm-email', data: {'token': token});
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data?['message'] ?? 'Check failed';
      final code = data?['code'] ?? 'UNKNOWN';
      throw AuthError(message, code);
    }
  }

  Future<void> resendConfirmation(String email) async {
    try {
      await _dio.post(
        '$_baseUrl/auth/resend-confirmation',
        data: {'email': email},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Resend failed';
      String code = 'UNKNOWN';

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        code = data['code'] ?? code;
      } else if (data is String) {
        message = data;
      }
      throw AuthError(message, code);
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? whatsappTemplate,
  }) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/users/me',
        data: {
          if (name != null) 'name': name,
          if (whatsappTemplate != null) 'whatsappTemplate': whatsappTemplate,
        },
      );
      return response.data; // { message, user }
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Update failed';
    }
  }
}
