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
}

final studentModuleListProvider = FutureProvider.autoDispose
    .family<StudentModulePage, StudentModuleQuery>(
      (ref, query) => ref
          .watch(studentModuleRepositoryProvider)
          .list(search: query.search, status: query.status),
    );
