import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'teacher_repository.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>(
  (ref) => TeacherRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final teacherDashboardProvider = FutureProvider<TeacherDashboardSummary>(
  (ref) => ref.watch(teacherRepositoryProvider).dashboard(),
);

final teacherClassesProvider = FutureProvider<TeacherClassPage>(
  (ref) => ref.watch(teacherRepositoryProvider).classes(),
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

final teacherClassDetailProvider = FutureProvider.family<TeacherClass, String>(
  (ref, id) => ref.watch(teacherRepositoryProvider).classDetail(id),
);

final teacherClassStudentsProvider =
    FutureProvider.family<TeacherClassStudentPage, String>(
      (ref, id) => ref.watch(teacherRepositoryProvider).classStudents(id),
    );
