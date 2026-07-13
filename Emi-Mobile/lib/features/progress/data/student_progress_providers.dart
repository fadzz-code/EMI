import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'student_progress.dart';
import 'student_progress_repository.dart';

final studentProgressRepositoryProvider = Provider<StudentProgressRepository>(
  (ref) =>
      StudentProgressRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

class StudentProgressQuery {
  const StudentProgressQuery({this.page = 1, this.perPage = 15});

  final int page;
  final int perPage;

  @override
  bool operator ==(Object other) {
    return other is StudentProgressQuery &&
        other.page == page &&
        other.perPage == perPage;
  }

  @override
  int get hashCode => Object.hash(page, perPage);
}

final studentProgressReportProvider = FutureProvider.autoDispose
    .family<StudentProgressReport, StudentProgressQuery>(
      (ref, query) => ref
          .watch(studentProgressRepositoryProvider)
          .report(page: query.page, perPage: query.perPage),
    );
