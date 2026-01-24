import 'dart:async'; // for TimeoutException
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/api_config.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

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
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn(
    scopes: ['email', 'profile'],
    // serverClientId is REQUIRED to get an idToken that the backend can verify.
    // Use the SAME Web Client ID from your server .env here.
    serverClientId: ApiConfig.googleServerClientId,
  );

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      debugPrint('DEBUG: Starting Google Sign In details...');

      // Force sign out for debugging
      await _googleSignIn.signOut();

      // 1. Native Sign In
      final gsi.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('DEBUG: Sign in aborted by user');
        throw AuthError('Sign in aborted by user', 'ABORTED');
      }

      debugPrint('DEBUG: User signed in: ${googleUser.email}');

      // 2. Get ID Token
      final gsi.GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      debugPrint('DEBUG: ID Token retrieved (Length: ${idToken?.length})');

      if (idToken == null) {
        throw AuthError('Failed to get ID Token from Google', 'TOKEN_ERROR');
      }

      // 3. Verify with Backend (with Timeout)
      debugPrint('DEBUG: Sending to backend: $_baseUrl/auth/google');

      final response = await _dio
          .post('$_baseUrl/auth/google', data: {'idToken': idToken})
          .timeout(
            const Duration(seconds: 30),
          ); // Fail fast if server unreachable

      debugPrint('DEBUG: Backend responded: ${response.statusCode}');

      return response.data; // { token, user }
    } on TimeoutException {
      debugPrint('DEBUG: Connection Timed Out!');
      throw AuthError('Timeout', 'TIMEOUT');
    } on DioException catch (e) {
      debugPrint('DEBUG: DioException: ${e.message} ${e.response?.data}');
      await _googleSignIn.signOut();
      final data = e.response?.data;
      String message = 'Google connection failed';
      String code = 'UNKNOWN';

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        code = data['code'] ?? code;
      }
      throw AuthError(message, code);
    } catch (e) {
      debugPrint('DEBUG: General Exception: $e');
      if (e is AuthError) rethrow;

      await _googleSignIn.signOut();
      throw AuthError('Google Sign In failed: ${e.toString()}', 'GOOGLE_ERROR');
    }
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await _dio
          .post(
            '$_baseUrl/auth/login',
            data: {'identifier': identifier, 'password': password},
          )
          .timeout(const Duration(seconds: 30));

      return response.data; // { token, user }
    } on TimeoutException {
      throw AuthError('Timeout', 'TIMEOUT');
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
      final response = await _dio
          .post(
            '$_baseUrl/auth/register',
            data: {
              'email': email,
              'password': password,
              'name': name,
              if (phone != null) 'phone': phone,
            },
          )
          .timeout(const Duration(seconds: 30));

      return response.data;
    } on TimeoutException {
      throw AuthError('Timeout', 'TIMEOUT');
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
