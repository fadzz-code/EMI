import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final adminDashboardProvider = FutureProvider<AdminSummary>(
  (ref) => ref.watch(adminRepositoryProvider).dashboard(),
);

final adminListProvider =
    FutureProvider.family<AdminListPage, AdminFeatureQuery>(
      (ref, query) => ref
          .watch(adminRepositoryProvider)
          .list(query.feature.endpoint, query.query),
    );

final adminDetailProvider =
    FutureProvider.family<AdminRecord, AdminDetailQuery>(
      (ref, query) => ref
          .watch(adminRepositoryProvider)
          .detail(query.feature.endpoint, query.id),
    );

final adminClassesProvider =
    AsyncNotifierProvider<AdminClassesController, AdminClassPage>(
      AdminClassesController.new,
    );

final adminClassDetailProvider = FutureProvider.family<AdminClass, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).classDetail(id),
);

final adminClassStudentsProvider =
    FutureProvider.family<AdminClassStudentPage, String>(
      (ref, id) => ref.watch(adminRepositoryProvider).classStudents(id),
    );

final adminSchoolsProvider =
    AsyncNotifierProvider<AdminSchoolsController, AdminSchoolPage>(
      AdminSchoolsController.new,
    );

final adminSchoolDetailProvider = FutureProvider.family<AdminSchool, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).schoolDetail(id),
);

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersController, AdminUserPage>(
      AdminUsersController.new,
    );

final adminUserDetailProvider = FutureProvider.family<AdminUser, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).userDetail(id),
);

class AdminClassesController extends AsyncNotifier<AdminClassPage> {
  AdminListQuery _query = const AdminListQuery();

  AdminListQuery get query => _query;

  @override
  Future<AdminClassPage> build() => _load(_query);

  Future<AdminClassPage> _load(AdminListQuery query) =>
      ref.read(adminRepositoryProvider).classes(query);

  Future<void> search(String value) async {
    _query = _query.copyWith(search: value, page: 1);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(_query));
  }

  Future<void> filter({String? schoolId, String? status}) async {
    _query = _query.copyWith(
      schoolId: schoolId,
      status: status,
      clearSchool: schoolId == null,
      clearStatus: status == null,
      page: 1,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(_query));
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _load(_query.copyWith(page: 1)));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || state.isLoading) return;
    final nextQuery = _query.copyWith(page: current.currentPage + 1);
    final next = await _load(nextQuery);
    final byId = {
      for (final item in [...current.items, ...next.items]) item.id: item,
    };
    _query = nextQuery;
    state = AsyncData(
      AdminClassPage(
        items: byId.values.toList(),
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
      ),
    );
  }
}

class AdminSchoolsController extends AsyncNotifier<AdminSchoolPage> {
  AdminListQuery _query = const AdminListQuery();

  AdminListQuery get query => _query;

  @override
  Future<AdminSchoolPage> build() => _load(_query);

  Future<AdminSchoolPage> _load(AdminListQuery query) =>
      ref.read(adminRepositoryProvider).schools(query);

  Future<void> search(String value) async {
    _query = _query.copyWith(search: value, page: 1);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(_query));
  }

  Future<void> filter({String? status}) async {
    _query = _query.copyWith(
      status: status,
      clearStatus: status == null,
      page: 1,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(_query));
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _load(_query.copyWith(page: 1)));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || state.isLoading) return;
    final nextQuery = _query.copyWith(page: current.currentPage + 1);
    final next = await _load(nextQuery);
    final byId = {
      for (final item in [...current.items, ...next.items]) item.id: item,
    };
    _query = nextQuery;
    state = AsyncData(
      AdminSchoolPage(
        items: byId.values.toList(),
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
      ),
    );
  }
}

class AdminUsersController extends AsyncNotifier<AdminUserPage> {
  AdminListQuery _query = const AdminListQuery();

  AdminListQuery get query => _query;

  @override
  Future<AdminUserPage> build() => _load(_query);

  Future<AdminUserPage> _load(AdminListQuery query) =>
      ref.read(adminRepositoryProvider).users(query);

  Future<void> search(String value) async {
    _query = _query.copyWith(search: value, page: 1);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(_query));
  }

  Future<void> filter({String? role, String? status}) async {
    _query = _query.copyWith(
      role: role,
      status: status,
      clearRole: role == null,
      clearStatus: status == null,
      page: 1,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(_query));
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _load(_query.copyWith(page: 1)));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || state.isLoading) return;
    final nextQuery = _query.copyWith(page: current.currentPage + 1);
    final next = await _load(nextQuery);
    final byId = {
      for (final item in [...current.items, ...next.items]) item.id: item,
    };
    _query = nextQuery;
    state = AsyncData(
      AdminUserPage(
        items: byId.values.toList(),
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
      ),
    );
  }
}

class AdminFeatureQuery {
  const AdminFeatureQuery({
    required this.feature,
    this.query = const AdminListQuery(),
  });

  final AdminFeature feature;
  final AdminListQuery query;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminFeatureQuery &&
          other.feature == feature &&
          other.query == query;

  @override
  int get hashCode => Object.hash(feature, query);
}

class AdminDetailQuery {
  const AdminDetailQuery({required this.feature, required this.id});

  final AdminFeature feature;
  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminDetailQuery && other.feature == feature && other.id == id;

  @override
  int get hashCode => Object.hash(feature, id);
}

enum AdminFeature {
  approvals(
    'Persetujuan Akun',
    '/admin/registration-requests',
    '/admin/approvals',
  ),
  users('Guru dan Siswa', '/users', '/admin/users'),
  schools('Sekolah', '/schools', '/admin/schools'),
  classes('Kelas', '/classes', '/admin/classes'),
  modules('Modul', '/admin/module-templates', '/admin/modules'),
  dictionary('Kamus', '/admin/dictionary/entries', '/admin/dictionary'),
  knowledge('Basis AI', '/admin/ai/knowledge', '/admin/knowledge'),
  quizzes('Kuis', '/admin/quiz-templates', '/admin/quizzes'),
  culture('Budaya', '/admin/culture/items', '/admin/culture'),
  speaking('Rekaman Speaking', '/admin/speaking/exercises', '/admin/speaking'),
  reports('Laporan', '/admin/reports/progress/students', '/admin/reports'),
  settings('Pengaturan', '/admin/settings', '/admin/settings');

  const AdminFeature(this.label, this.endpoint, this.route);

  final String label;
  final String endpoint;
  final String route;

  bool get isMobileImplemented => switch (this) {
    AdminFeature.approvals ||
    AdminFeature.users ||
    AdminFeature.schools ||
    AdminFeature.classes ||
    AdminFeature.dictionary ||
    AdminFeature.knowledge ||
    AdminFeature.quizzes ||
    AdminFeature.reports ||
    AdminFeature.settings => true,
    _ => false,
  };
}
