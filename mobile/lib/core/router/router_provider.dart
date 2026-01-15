import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/students/presentation/screens/student_list_screen.dart';
import '../../features/students/presentation/screens/student_detail_screen.dart';
import '../../features/attendance/presentation/screens/attendance_session_list_screen.dart';
import '../../features/attendance/presentation/screens/take_attendance_screen.dart';
import '../../features/classes/presentation/screens/class_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../core/components/scaffold_with_navbar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: AuthNotifier(
      ref,
    ), // TODO: Properly implement refresh listner
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';

      if (!isLoggedIn && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return '/';
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Students Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const StudentListScreen(),
                routes: [
                  GoRoute(
                    path: 'students/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return StudentDetailScreen(studentId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Attendance Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/attendance',
                builder: (context, state) =>
                    const AttendanceSessionListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const TakeAttendanceScreen(),
                  ),
                  // TODO: Add session detail route later
                  // GoRoute(
                  //   path: ':sessionId',
                  //   builder: (context, state) => AttendanceDetailScreen(sessionId: state.pathParameters['sessionId']!),
                  // ),
                ],
              ),
            ],
          ),
          // Classes Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/classes',
                builder: (context, state) => const ClassListScreen(),
              ),
            ],
          ),
          // Settings Tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
