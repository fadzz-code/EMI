import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'student_dashboard_repository.dart';
import 'student_dashboard_summary.dart';

final studentDashboardRepositoryProvider = Provider<StudentDashboardRepository>(
  (ref) => StudentDashboardRepository(
    ref.watch(dioProvider),
    const DioErrorMapper(),
  ),
);

final studentDashboardSummaryProvider = FutureProvider<StudentDashboardSummary>(
  (ref) => ref.watch(studentDashboardRepositoryProvider).summary(),
);
