import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/student_dashboard_screen.dart';
import '../../features/dictionary/presentation/dictionary_detail_screen.dart';
import '../../features/dictionary/presentation/dictionary_list_screen.dart';
import '../../features/modules/presentation/student_lesson_detail_screen.dart';
import '../../features/modules/presentation/student_module_detail_screen.dart';
import '../../features/modules/presentation/student_modules_screen.dart';
import '../../features/profile/presentation/student_profile_screen.dart';
import '../../features/quizzes/presentation/student_quiz_attempt_screen.dart';
import '../../features/quizzes/presentation/student_quiz_detail_screen.dart';
import '../../features/quizzes/presentation/student_quizzes_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'router_refresh_stream.dart';
import 'unsupported_role_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.uri.path;

      if (auth.status == AuthStatus.unknown) {
        return location == '/splash' ? null : '/splash';
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return location == '/login' ? null : '/login';
      }
      if (auth.status == AuthStatus.unsupportedRole) {
        return location == '/unsupported-role' ? null : '/unsupported-role';
      }
      if (auth.status == AuthStatus.authenticated) {
        if (location == '/login' || location == '/splash' || location == '/') {
          return '/student/dashboard';
        }
      }
      return null;
    },
    refreshListenable: RouterRefreshNotifier(ref),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/student/dashboard',
        builder: (_, _) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/student/modules',
        builder: (_, _) => const StudentModulesScreen(),
      ),
      GoRoute(
        path: '/student/modules/:moduleId',
        builder: (_, state) => StudentModuleDetailScreen(
          moduleId: state.pathParameters['moduleId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/student/lessons/:lessonId',
        builder: (_, state) => StudentLessonDetailScreen(
          lessonId: state.pathParameters['lessonId'] ?? '',
          moduleId: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/student/dictionary',
        builder: (_, _) => const DictionaryListScreen(),
      ),
      GoRoute(
        path: '/student/dictionary/:entryId',
        builder: (_, state) => DictionaryDetailScreen(
          entryId: state.pathParameters['entryId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/student/quizzes',
        builder: (_, _) => const StudentQuizzesScreen(),
      ),
      GoRoute(
        path: '/student/quizzes/:quizId',
        builder: (_, state) => StudentQuizDetailScreen(
          quizId: state.pathParameters['quizId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/student/quizzes/:quizId/attempt',
        builder: (_, state) => StudentQuizAttemptScreen(
          quizId: state.pathParameters['quizId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/student/profile',
        builder: (_, _) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: '/unsupported-role',
        builder: (_, _) => const UnsupportedRoleScreen(),
      ),
    ],
    errorBuilder: (_, _) =>
        const UnsupportedRoleScreen(message: 'Halaman tidak ditemukan.'),
  );
});

class RouterRefreshNotifier extends GoRouterRefreshStream {
  RouterRefreshNotifier(Ref ref)
    : super(ref.watch(authControllerProvider.notifier).stream);
}
