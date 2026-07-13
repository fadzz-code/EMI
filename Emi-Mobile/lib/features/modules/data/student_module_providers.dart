import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'student_module.dart';
import 'student_module_repository.dart';

final studentModuleRepositoryProvider = Provider<StudentModuleRepository>(
  (ref) =>
      StudentModuleRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

class StudentModuleQuery {
  const StudentModuleQuery({this.search, this.status});

  final String? search;
  final String? status;

  @override
  bool operator ==(Object other) {
    return other is StudentModuleQuery &&
        other.search == search &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(search, status);
}

final studentModuleListProvider = FutureProvider.autoDispose
    .family<StudentModulePage, StudentModuleQuery>(
      (ref, query) => ref
          .watch(studentModuleRepositoryProvider)
          .list(search: query.search, status: query.status),
    );

final studentModuleDetailProvider = FutureProvider.autoDispose
    .family<StudentModule, String>(
      (ref, moduleId) =>
          ref.watch(studentModuleRepositoryProvider).detail(moduleId),
    );

final studentLessonDetailProvider = FutureProvider.autoDispose
    .family<StudentLesson, String>(
      (ref, lessonId) =>
          ref.watch(studentModuleRepositoryProvider).lesson(lessonId),
    );

final studentLessonContentProvider = FutureProvider.autoDispose
    .family<LessonContent?, String>(
      (ref, lessonId) =>
          ref.watch(studentModuleRepositoryProvider).lessonContent(lessonId),
    );
