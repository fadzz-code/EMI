import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import '../../culture/data/culture_models.dart';
import 'teacher_quiz_models.dart';
import 'teacher_quiz_repository.dart';
import 'teacher_repository.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>(
  (ref) => TeacherRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final teacherRegistrationRequestsProvider =
    FutureProvider.family<
      TeacherRequestPage,
      ({int page, String search, String status})
    >(
      (ref, query) => ref
          .watch(teacherRepositoryProvider)
          .registrationRequests(
            page: query.page,
            search: query.search,
            status: query.status,
          ),
    );
final teacherRegistrationRequestProvider =
    FutureProvider.family<TeacherRequestItem, String>(
      (ref, id) => ref.watch(teacherRepositoryProvider).registrationRequest(id),
    );
final teacherPasswordResetRequestsProvider =
    FutureProvider.family<
      TeacherRequestPage,
      ({int page, String search, String status})
    >(
      (ref, query) => ref
          .watch(teacherRepositoryProvider)
          .passwordResetRequests(
            page: query.page,
            search: query.search,
            status: query.status,
          ),
    );
final teacherPasswordResetRequestProvider =
    FutureProvider.family<TeacherRequestItem, String>(
      (ref, id) =>
          ref.watch(teacherRepositoryProvider).passwordResetRequest(id),
    );

final teacherSpeakingTemplatesProvider =
    FutureProvider<List<TeacherSpeakingTemplate>>(
      (ref) => ref.watch(teacherRepositoryProvider).speakingTemplates(),
    );
final teacherSpeakingExercisesProvider =
    FutureProvider.family<
      List<TeacherSpeakingExercise>,
      ({String classroomId, String status})
    >(
      (ref, value) => ref
          .watch(teacherRepositoryProvider)
          .speakingExercises(
            classroomId: value.classroomId,
            status: value.status,
          ),
    );
final teacherSpeakingExerciseProvider =
    FutureProvider.family<TeacherSpeakingExercise, String>(
      (ref, id) => ref.watch(teacherRepositoryProvider).speakingExercise(id),
    );
final teacherSpeakingAttemptsProvider =
    FutureProvider<List<TeacherSpeakingAttempt>>(
      (ref) => ref.watch(teacherRepositoryProvider).speakingAttempts(),
    );
final teacherSpeakingAttemptProvider =
    FutureProvider.family<TeacherSpeakingAttempt, String>(
      (ref, id) => ref.watch(teacherRepositoryProvider).speakingAttempt(id),
    );

final teacherDashboardProvider = FutureProvider<TeacherDashboardSummary>(
  (ref) => ref.watch(teacherRepositoryProvider).dashboard(),
);

final teacherClassesProvider =
    FutureProvider.family<TeacherClassPage, ({int page, String search})>(
      (ref, query) => ref
          .watch(teacherRepositoryProvider)
          .classes(page: query.page, search: query.search),
    );

final teacherCultureProvider = FutureProvider.family<CulturePage, String>(
  (ref, classId) => ref.watch(teacherRepositoryProvider).culture(classId),
);

final teacherCultureDetailProvider = FutureProvider.family<CultureItem, String>(
  (ref, id) => ref.watch(teacherRepositoryProvider).cultureDetail(id),
);

final teacherModulesProvider =
    FutureProvider.family<List<TeacherModule>, String>(
      (ref, classId) => ref.watch(teacherRepositoryProvider).modules(classId),
    );

final teacherModuleDetailProvider =
    FutureProvider.family<TeacherModule, String>(
      (ref, id) => ref.watch(teacherRepositoryProvider).moduleDetail(id),
    );

final teacherLessonDetailProvider =
    FutureProvider.family<TeacherLesson, String>(
      (ref, id) => ref.watch(teacherRepositoryProvider).lessonDetail(id),
    );

final teacherLessonContentProvider =
    FutureProvider.family<TeacherLessonContent, String>(
      (ref, id) => ref.watch(teacherRepositoryProvider).lessonContent(id),
    );

final teacherClassDetailProvider = FutureProvider.family<TeacherClass, String>(
  (ref, id) => ref.watch(teacherRepositoryProvider).classDetail(id),
);

final teacherClassStudentsProvider =
    FutureProvider.family<
      TeacherClassStudentPage,
      ({String classId, int page, String search})
    >(
      (ref, query) => ref
          .watch(teacherRepositoryProvider)
          .classStudents(query.classId, page: query.page, search: query.search),
    );

final teacherStudentProgressProvider =
    FutureProvider.family<
      TeacherStudentProgressPage,
      ({int page, String search})
    >(
      (ref, query) => ref
          .watch(teacherRepositoryProvider)
          .studentProgress(page: query.page, search: query.search),
    );

final teacherClassProgressProvider =
    FutureProvider.family<
      TeacherStudentProgressPage,
      ({String classId, int page, String search})
    >(
      (ref, query) => ref
          .watch(teacherRepositoryProvider)
          .studentProgress(
            page: query.page,
            classId: query.classId,
            search: query.search,
          ),
    );

final teacherStudentDetailProvider =
    FutureProvider.family<TeacherStudentProgress, String>(
      (ref, id) => ref.watch(teacherRepositoryProvider).studentDetail(id),
    );

final teacherClassQuizzesProvider =
    FutureProvider.family<TeacherQuizPage, String>(
      (ref, id) => ref.watch(teacherQuizRepositoryProvider).classList(id),
    );

final teacherQuizRepositoryProvider = Provider<TeacherQuizRepository>(
  (ref) =>
      TeacherQuizRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final teacherQuizzesProvider =
    FutureProvider.family<
      TeacherQuizPage,
      ({int page, String search, String status})
    >(
      (ref, filter) => ref
          .watch(teacherQuizRepositoryProvider)
          .list(
            page: filter.page,
            search: filter.search,
            status: filter.status,
          ),
    );
final teacherQuizDetailProvider = FutureProvider.family<TeacherQuiz, String>(
  (ref, id) => ref.watch(teacherQuizRepositoryProvider).detail(id),
);
final teacherQuizQuestionProvider =
    FutureProvider.family<TeacherQuizQuestion, String>(
      (ref, id) => ref.watch(teacherQuizRepositoryProvider).question(id),
    );
final teacherQuizAttemptsProvider =
    FutureProvider.family<
      TeacherQuizAttemptPage,
      ({String quizId, int page, String status})
    >(
      (ref, value) => ref
          .watch(teacherQuizRepositoryProvider)
          .attempts(value.quizId, page: value.page, status: value.status),
    );
final teacherQuizReportProvider =
    FutureProvider.family<
      TeacherQuizResultPage,
      ({int page, String quizId, String status})
    >(
      (ref, value) => ref
          .watch(teacherQuizRepositoryProvider)
          .report(page: value.page, quizId: value.quizId, status: value.status),
    );

final teacherQuizAttemptProvider =
    FutureProvider.family<TeacherQuizAttempt, String>(
      (ref, id) => ref.watch(teacherQuizRepositoryProvider).attempt(id),
    );
