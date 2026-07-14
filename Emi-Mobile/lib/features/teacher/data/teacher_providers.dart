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
