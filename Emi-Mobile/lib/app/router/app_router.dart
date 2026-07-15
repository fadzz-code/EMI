import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/data/admin_providers.dart';
import '../../features/admin/presentation/admin_approvals_screens.dart';
import '../../features/admin/presentation/admin_dictionary_screens.dart';
import '../../features/admin/presentation/admin_knowledge_screens.dart';
import '../../features/admin/presentation/admin_quiz_screens.dart';
import '../../features/admin/presentation/admin_reports_screen.dart';
import '../../features/admin/presentation/admin_screens.dart';
import '../../features/admin/presentation/admin_settings_screen.dart';
import '../../features/auth/presentation/account_status_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
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

      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/reset-password';
      final isStatusRoute = location == '/account-status';

      if (auth.status == AuthStatus.initializing) {
        return location == '/splash' ? null : '/splash';
      }
      if (auth.status == AuthStatus.unauthenticated ||
          auth.status == AuthStatus.sessionExpired) {
        return isAuthRoute ? null : '/login';
      }
      if (auth.status == AuthStatus.pendingApproval ||
          auth.status == AuthStatus.registrationRejected ||
          auth.status == AuthStatus.accountDisabled ||
          auth.status == AuthStatus.forbidden) {
        return isStatusRoute ? null : '/account-status';
      }
      if (auth.status == AuthStatus.unsupportedRole) {
        return location == '/unsupported-role' ? null : '/unsupported-role';
      }
      if (auth.status.isAuthenticated) {
        final home = switch (auth.status) {
          AuthStatus.authenticatedAdmin => '/admin/dashboard',
          AuthStatus.authenticatedTeacher => '/teacher/dashboard',
          AuthStatus.authenticatedStudent => '/student/dashboard',
          _ => '/login',
        };
        if (isAuthRoute || location == '/splash' || location == '/') {
          return home;
        }
        if (location.startsWith('/admin') &&
            auth.status != AuthStatus.authenticatedAdmin) {
          return home;
        }
        if (location.startsWith('/student') &&
            auth.status != AuthStatus.authenticatedStudent) {
          return home;
        }
        if (location.startsWith('/teacher') &&
            auth.status != AuthStatus.authenticatedTeacher) {
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
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/account-status',
        builder: (_, _) => const AccountStatusScreen(),
      ),
      GoRoute(path: '/teacher', redirect: (_, _) => '/teacher/dashboard'),
      GoRoute(
        path: '/teacher/dashboard',
        builder: (_, _) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: '/teacher/profile',
        builder: (_, _) => const StudentProfileScreen(),
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
        path: '/admin/users',
        builder: (_, _) => const AdminListScreen(feature: AdminFeature.users),
      ),
      GoRoute(
        path: '/admin/users/:id',
        builder: (_, state) => AdminDetailScreen(
          feature: AdminFeature.users,
          id: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/admin/schools',
        builder: (_, _) => const AdminListScreen(feature: AdminFeature.schools),
      ),
      GoRoute(
        path: '/admin/schools/create',
        builder: (_, _) => const AdminSchoolFormScreen(),
      ),
      GoRoute(
        path: '/admin/schools/:id/edit',
        builder: (_, state) =>
            AdminSchoolFormScreen(id: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/schools/:id',
        builder: (_, state) => AdminDetailScreen(
          feature: AdminFeature.schools,
          id: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/admin/classes',
        builder: (_, _) => const AdminListScreen(feature: AdminFeature.classes),
      ),
      GoRoute(
        path: '/admin/classes/create',
        builder: (_, _) => const AdminClassFormScreen(),
      ),
      GoRoute(
        path: '/admin/classes/:id/edit',
        builder: (_, state) =>
            AdminClassFormScreen(id: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/classes/:id',
        builder: (_, state) => AdminDetailScreen(
          feature: AdminFeature.classes,
          id: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/admin/dictionary',
        builder: (_, _) => const AdminDictionaryScreen(),
      ),
      GoRoute(
        path: '/admin/dictionary/create',
        builder: (_, _) => const AdminDictionaryFormScreen(),
      ),
      GoRoute(
        path: '/admin/dictionary/categories',
        builder: (_, _) => const AdminDictionaryCategoryScreen(),
      ),
      GoRoute(
        path: '/admin/dictionary/import',
        builder: (_, _) => const AdminDictionaryImportScreen(),
      ),
      GoRoute(
        path: '/admin/dictionary/:id/edit',
        builder: (_, state) =>
            AdminDictionaryFormScreen(id: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/dictionary/:id',
        builder: (_, state) =>
            AdminDictionaryDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/admin/knowledge',
        builder: (_, _) => const AdminKnowledgeScreen(),
      ),
      GoRoute(
        path: '/admin/knowledge/create',
        builder: (_, _) => const AdminKnowledgeFormScreen(),
      ),
      GoRoute(
        path: '/admin/knowledge/:id/edit',
        builder: (_, state) =>
            AdminKnowledgeFormScreen(id: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/knowledge/:id',
        builder: (_, state) =>
            AdminKnowledgeDetailScreen(id: state.pathParameters['id'] ?? ''),
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
        path: '/admin/profile',
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
