import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_approvals_screens.dart';
import '../../features/admin/presentation/admin_dictionary_screens.dart';
import '../../features/admin/presentation/admin_quiz_screens.dart';
import '../../features/admin/presentation/admin_reports_screen.dart';
import '../../features/admin/presentation/admin_screens.dart';
import '../../features/admin/presentation/admin_settings_screen.dart';
import '../../features/auth/domain/session_user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/chatbot/presentation/student_chatbot_screen.dart';
import '../../features/culture/data/culture_models.dart';
import '../../features/culture/presentation/student_culture_detail_screen.dart';
import '../../features/culture/presentation/student_culture_list_screen.dart';
import '../../features/dashboard/presentation/student_dashboard_screen.dart';
import '../../features/dictionary/presentation/dictionary_detail_screen.dart';
import '../../features/dictionary/presentation/dictionary_list_screen.dart';
import '../../features/modules/presentation/student_lesson_detail_screen.dart';
import '../../features/modules/presentation/student_module_detail_screen.dart';
import '../../features/modules/presentation/student_modules_screen.dart';
import '../../features/profile/presentation/student_profile_screen.dart';
import '../../features/progress/presentation/student_progress_screen.dart';
import '../../features/quizzes/presentation/student_quiz_attempt_screen.dart';
import '../../features/quizzes/presentation/student_quiz_detail_screen.dart';
import '../../features/quizzes/presentation/student_quizzes_screen.dart';
import '../../features/speaking/presentation/student_speaking_detail_screen.dart';
import '../../features/speaking/presentation/student_speaking_list_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/teacher/presentation/teacher_dashboard_screen.dart';
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
        final home = switch (auth.user?.role) {
          UserRole.admin => '/admin/dashboard',
          UserRole.teacher => '/teacher/dashboard',
          _ => '/student/dashboard',
        };
        if (location == '/login' || location == '/splash' || location == '/') {
          return home;
        }
        if (location.startsWith('/admin') &&
            auth.user?.role != UserRole.admin) {
          return home;
        }
        if (location.startsWith('/student') &&
            auth.user?.role != UserRole.student) {
          return home;
        }
        if (location.startsWith('/teacher') &&
            auth.user?.role != UserRole.teacher) {
          return home;
        }
      }
      return null;
    },
    refreshListenable: RouterRefreshNotifier(ref),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/teacher', redirect: (_, _) => '/teacher/dashboard'),
      GoRoute(
        path: '/teacher/dashboard',
        builder: (_, _) => const TeacherDashboardScreen(),
      ),
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
        path: '/student/progress',
        builder: (_, _) => const StudentProgressScreen(),
      ),
      GoRoute(
        path: '/student/chatbot',
        builder: (_, _) => const StudentChatbotScreen(),
      ),
      GoRoute(
        path: '/student/culture',
        builder: (_, _) => const StudentCultureListScreen(),
      ),
      GoRoute(
        path: '/student/culture/:cultureId',
        builder: (_, state) => StudentCultureDetailScreen(
          cultureId: state.pathParameters['cultureId'] ?? '',
          item: state.extra is CultureItem ? state.extra as CultureItem : null,
        ),
      ),
      GoRoute(
        path: '/student/speaking',
        builder: (_, _) => const StudentSpeakingListScreen(),
      ),
      GoRoute(
        path: '/student/speaking/:exerciseId',
        builder: (_, state) => StudentSpeakingDetailScreen(
          exerciseId: state.pathParameters['exerciseId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/student/profile',
        builder: (_, _) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, _) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/approvals',
        builder: (_, _) => const AdminApprovalsScreen(),
      ),
      GoRoute(
        path: '/admin/approvals/:id',
        builder: (_, state) =>
            AdminApprovalDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/admin/dictionary',
        builder: (_, _) => const AdminDictionaryScreen(),
      ),
      GoRoute(
        path: '/admin/dictionary/:id',
        builder: (_, state) =>
            AdminDictionaryFormScreen(id: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/quizzes',
        builder: (_, _) => const AdminQuizScreen(),
      ),
      GoRoute(
        path: '/admin/quizzes/:id',
        builder: (_, state) =>
            AdminQuizFormScreen(id: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/quizzes/:quizId/questions',
        builder: (_, state) => AdminQuestionListScreen(
          quizId: state.pathParameters['quizId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/admin/quizzes/:quizId/questions/:id',
        builder: (_, state) => AdminQuestionFormScreen(
          quizId: state.pathParameters['quizId'] ?? '',
          id: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (_, _) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (_, _) => const AdminSettingsScreen(),
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
