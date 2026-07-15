import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_progress_models.dart';
import 'admin_progress_repository.dart';

final adminProgressRepositoryProvider = Provider(
  (ref) =>
      AdminProgressRepository(ref.watch(dioProvider), const DioErrorMapper()),
);
final adminProgressProvider =
    AsyncNotifierProvider<AdminProgressController, AdminProgressOverview>(
      AdminProgressController.new,
    );
final adminProgressSchoolsProvider = FutureProvider(
  (ref) => ref.watch(adminProgressRepositoryProvider).schools(),
);
final adminProgressClassesProvider =
    FutureProvider.family<List<AdminProgressOption>, String?>(
      (ref, schoolId) =>
          ref.watch(adminProgressRepositoryProvider).classes(schoolId),
    );
final adminStudentProgressProvider =
    FutureProvider.family<AdminStudentProgressDetail, ({String id, int page})>(
      (ref, query) => ref
          .watch(adminProgressRepositoryProvider)
          .student(query.id, page: query.page),
    );
final adminClassProgressProvider =
    FutureProvider.family<AdminClassProgressDetail, ({String id, int page})>(
      (ref, query) => ref
          .watch(adminProgressRepositoryProvider)
          .schoolClass(query.id, page: query.page),
    );

class AdminProgressController extends AsyncNotifier<AdminProgressOverview> {
  AdminProgressFilters filters = const AdminProgressFilters();
  int studentPage = 1;
  int classPage = 1;

  @override
  Future<AdminProgressOverview> build() => _load();
  Future<AdminProgressOverview> _load() => ref
      .read(adminProgressRepositoryProvider)
      .overview(filters, studentPage: studentPage, classPage: classPage);

  Future<void> apply(AdminProgressFilters value) async {
    filters = value;
    studentPage = 1;
    classPage = 1;
    await refresh();
  }

  Future<void> students(int page) async {
    studentPage = page;
    await refresh();
  }

  Future<void> classes(int page) async {
    classPage = page;
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}
