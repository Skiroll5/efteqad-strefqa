import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/pending_activation_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/students/presentation/screens/student_list_screen.dart';
import '../../features/students/presentation/screens/student_detail_screen.dart';
import '../../features/attendance/presentation/screens/attendance_session_list_screen.dart';
import '../../features/attendance/presentation/screens/take_attendance_screen.dart';
import '../../features/attendance/presentation/screens/attendance_detail_screen.dart';
import '../../features/classes/presentation/screens/class_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/whatsapp_template_screen.dart';
import '../../features/settings/presentation/screens/denied_activations_screen.dart';
import '../../features/settings/presentation/pages/notification_settings_page.dart';
import '../../features/admin/presentation/screens/admin_panel_screen.dart';
import '../../features/admin/presentation/screens/user_management_screen.dart';
import '../../features/admin/presentation/screens/class_management_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: AuthNotifier(ref),
    redirect: (context, state) {
      if (authState.isLoading) return '/splash';

      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';
      final isForgotPassword = state.uri.toString() == '/forgot-password';
      final isVerifyResetOtp = state.uri.toString().startsWith(
        '/verify-reset-otp',
      );
      final isResetPassword = state.uri.toString().startsWith(
        '/reset-password',
      );
      final isConfirmPending = state.uri.toString() == '/confirm-email-pending';
      final isSplash = state.uri.toString() == '/splash';

      if (isSplash && isLoggedIn) return '/';
      if (isSplash && !isLoggedIn) return '/login';

      if (!isLoggedIn &&
          !isLoggingIn &&
          !isRegistering &&
          !isForgotPassword &&
          !isVerifyResetOtp &&
          !isResetPassword &&
          !isConfirmPending) {
        return '/login';
      }

      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return '/';
      }

      // Handle inactive users
      final user = authState.asData?.value;
      final isActive = user?.isActive ?? false;
      final isPending = state.uri.toString() == '/pending-activation';

      if (isLoggedIn && !isActive && !isPending) {
        // If user is logged in but not active, redirect to pending screen
        // unless they are already there
        return '/pending-activation';
      }

      if (isLoggedIn && isActive && isPending) {
        // If user became active but is on pending screen, go home
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      // Home (Class Selection)
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      // Students List (after class selected)
      GoRoute(
        path: '/students',
        builder: (context, state) => const StudentListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return StudentDetailScreen(studentId: id);
            },
          ),
        ],
      ),
      // Attendance
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendanceSessionListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const TakeAttendanceScreen(),
          ),
          GoRoute(
            path: ':sessionId',
            builder: (context, state) => AttendanceDetailScreen(
              sessionId: state.pathParameters['sessionId']!,
            ),
          ),
        ],
      ),
      // Classes (Admin only)
      GoRoute(
        path: '/classes',
        builder: (context, state) => const ClassListScreen(),
      ),
      // Admin Panel (Admin only)
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPanelScreen(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: 'classes',
            builder: (context, state) => const ClassManagementScreen(),
          ),
        ],
      ),
      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'whatsapp-template',
            builder: (context, state) => const WhatsAppTemplateScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationSettingsPage(),
          ),
          GoRoute(
            path: 'denied-activations',
            builder: (context, state) => const DeniedActivationsScreen(),
          ),
        ],
      ),
      // Auth
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pending-activation',
        builder: (context, state) => const PendingActivationScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final token = extra?['token'] as String? ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/verify-reset-otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final identifier = extra?['identifier'] as String? ?? '';
          return OtpVerificationScreen(
            identifier: identifier,
            purpose: OtpPurpose.passwordReset,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/confirm-email-pending',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          return OtpVerificationScreen(
            identifier: email,
            purpose: OtpPurpose.emailConfirmation,
          );
        },
      ),
    ],
  );
});

// Helper to notify router when auth state changes
class AuthNotifier extends ChangeNotifier {
  final Ref _ref;
  AuthNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
