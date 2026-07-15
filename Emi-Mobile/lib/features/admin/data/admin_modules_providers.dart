import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_modules_repository.dart';

final adminModuleRepositoryProvider = Provider<AdminModuleRepository>(
  (ref) =>
      AdminModuleRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final adminModuleSummaryProvider = FutureProvider<AdminModuleSummary>(
  (ref) => ref.watch(adminModuleRepositoryProvider).summary(),
);

final adminModulesProvider =
    AsyncNotifierProvider<AdminModuleController, AdminModulePage>(
      AdminModuleController.new,
    );

final adminModuleDetailProvider =
    FutureProvider.family<AdminModuleItem, String>(
      (ref, id) => ref.watch(adminModuleRepositoryProvider).detail(id),
    );

final adminModuleMaterialsProvider =
    FutureProvider.family<List<AdminLessonItem>, String>(
      (ref, id) => ref.watch(adminModuleRepositoryProvider).lessons(id),
    );

class AdminModuleController extends AsyncNotifier<AdminModulePage> {
  AdminModuleQuery _query = const AdminModuleQuery();
  int _request = 0;

  AdminModuleQuery get query => _query;

  @override
  Future<AdminModulePage> build() => _load(_query);

  Future<AdminModulePage> _load(AdminModuleQuery query) =>
      ref.read(adminModuleRepositoryProvider).list(query);

  Future<void> search(String value) async {
    _query = _query.copyWith(search: value, page: 1);
    final request = ++_request;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() => _load(_query));
    if (request == _request) state = next;
  }

  Future<void> filter({String? status}) async {
    _query = _query.copyWith(
      status: status,
      clearStatus: status == null,
      page: 1,
    );
    final request = ++_request;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() => _load(_query));
    if (request == _request) state = next;
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
      AdminModulePage(
        items: byId.values.toList(),
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
      ),
    );
  }
}
