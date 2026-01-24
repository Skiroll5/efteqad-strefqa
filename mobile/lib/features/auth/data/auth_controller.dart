import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/app_database.dart' hide User;
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:mobile/core/data/fcm_repository.dart';
import '../../sync/data/sync_service.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
      return AuthController(ref, ref.watch(appDatabaseProvider));
    });

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  final AppDatabase _db;

  AuthController(this._ref, this._db) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userData = prefs.getString('user_data');

      if (token != null && userData != null) {
        final user = User.fromJson(jsonDecode(userData));
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // If error (e.g. corrupt json), logout
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      final data = await repo.signInWithGoogle();

      final user = User.fromJson(data['user']);
      final token = data['token'];

      // Save token and user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user_data', jsonEncode(user.toJson()));

      // Upsert user to local DB
      await _upsertUserLocal(user);

      // Register FCM Token
      try {
        final notifService = _ref.read(notificationServiceProvider);
        final token = await notifService.getToken();
        if (token != null) {
          final fcmRepo = _ref.read(fcmRepositoryProvider);
          await fcmRepo.registerToken(token);
        }
      } catch (e) {
        // FCM error is non-fatal
      }

      state = AsyncValue.data(user);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> login(String identifier, String password) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      final data = await repo.login(identifier, password);

      final user = User.fromJson(data['user']);
      final token = data['token'];

      // Save token and user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user_data', jsonEncode(user.toJson()));

      // Upsert user to local DB so joins work immediately
      await _upsertUserLocal(user);

      // Register FCM Token
      try {
        final notifService = _ref.read(notificationServiceProvider);
        final token = await notifService.getToken();
        if (token != null) {
          final fcmRepo = _ref.read(fcmRepositoryProvider);
          await fcmRepo.registerToken(token);
        }
      } catch (e) {
        // FCM error is non-fatal for login
      }

      state = AsyncValue.data(user);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String name, {
    String? phone,
  }) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.register(email, password, name, phone: phone);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPassword(String identifier) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.forgotPassword(identifier);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmEmail(String token) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.confirmEmail(token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resendConfirmation(String email) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.resendConfirmation(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.resetPassword(token, newPassword);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyResetOtp(String otp) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.verifyResetOtp(otp);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateWhatsAppTemplate(String template) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      final data = await repo.updateProfile(whatsappTemplate: template);

      final updatedUser = User.fromJson(data['user']);

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

      // Upsert user to local DB
      await _upsertUserLocal(updatedUser);

      state = AsyncValue.data(updatedUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    // Clear local DB to prevent data leakage between users
    try {
      await _ref.read(syncServiceProvider).clearLocalData();
    } catch (e) {
      // print('Error clearing local data: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_data');
    state = const AsyncValue.data(null);
  }

  Future<void> _upsertUserLocal(User user) async {
    await _db
        .into(_db.users)
        .insertOnConflictUpdate(
          UsersCompanion(
            id: Value(user.id),
            email: Value(user.email),
            name: Value(user.name),
            role: Value(user.role),
            classId: Value(user.classId),
            whatsappTemplate: Value(user.whatsappTemplate),
            isActive: Value(user.isActive),
            createdAt: Value(user.createdAt ?? DateTime.now()),
            updatedAt: Value(user.updatedAt ?? DateTime.now()),
            isDeleted: const Value(false),
          ),
        );
  }
}
