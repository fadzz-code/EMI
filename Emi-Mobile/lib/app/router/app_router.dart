import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/student_dashboard_screen.dart';
import '../../features/modules/presentation/student_modules_screen.dart';
import '../../features/profile/presentation/student_profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'router_refresh_stream.dart';
import 'unsupported_role_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.uri.path;

      if (auth.status == AuthStatus.unknown)
        return location == '/splash' ? null : '/splash';
      if (auth.status == AuthStatus.unauthenticated)
        return location == '/login' ? null : '/login';
      if (auth.status == AuthStatus.unsupportedRole)
        return location == '/unsupported-role' ? null : '/unsupported-role';
      if (auth.status == AuthStatus.authenticated) {
        if (location == '/login' || location == '/splash' || location == '/')
          return '/student/dashboard';
      }
      return null;
    },
    refreshListenable: RouterRefreshNotifier(ref),
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/splash'),
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/student/dashboard',
        builder: (_, __) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/student/modules',
        builder: (_, __) => const StudentModulesScreen(),
      ),
      GoRoute(
        path: '/student/modules/:id',
        builder: (_, __) => const StudentModulesScreen(),
      ),
      GoRoute(
        path: '/student/profile',
        builder: (_, __) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: '/unsupported-role',
        builder: (_, __) => const UnsupportedRoleScreen(),
      ),
    ],
    errorBuilder: (_, __) =>
        const UnsupportedRoleScreen(message: 'Halaman tidak ditemukan.'),
  );
});

class RouterRefreshNotifier extends GoRouterRefreshStream {
  RouterRefreshNotifier(Ref ref)
    : super(ref.watch(authControllerProvider.notifier).stream);
}
