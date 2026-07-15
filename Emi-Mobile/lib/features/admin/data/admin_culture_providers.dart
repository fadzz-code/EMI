import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_culture_repository.dart';

final adminCultureRepositoryProvider = Provider<AdminCultureRepository>(
  (ref) =>
      AdminCultureRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final adminCultureItemsProvider =
    AsyncNotifierProvider<AdminCultureController, AdminCulturePage>(
      AdminCultureController.new,
    );

final adminCultureDetailProvider =
    FutureProvider.family<AdminCultureItem, String>(
      (ref, id) => ref.watch(adminCultureRepositoryProvider).detail(id),
    );

class AdminCultureController extends AsyncNotifier<AdminCulturePage> {
  AdminCultureQuery _query = const AdminCultureQuery();
  int _request = 0;
  bool _loadingMore = false;

  AdminCultureQuery get query => _query;

  @override
  Future<AdminCulturePage> build() => _load(_query);

  Future<AdminCulturePage> _load(AdminCultureQuery query) =>
      ref.read(adminCultureRepositoryProvider).list(query);

  Future<void> search(String value) async {
    _query = _query.copyWith(search: value, page: 1);
    await _replace();
  }

  Future<void> filter({String? status, String? contentType}) async {
    _query = _query.copyWith(
      status: status,
      contentType: contentType,
      clearStatus: status == null,
      clearContentType: contentType == null,
      page: 1,
    );
    await _replace();
  }

  Future<void> _replace() async {
    final request = ++_request;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() => _load(_query));
    if (request == _request) state = next;
  }

  Future<void> refresh() async {
    _query = _query.copyWith(page: 1);
    state = await AsyncValue.guard(() => _load(_query));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final nextQuery = _query.copyWith(page: current.currentPage + 1);
      final next = await _load(nextQuery);
      final byId = {
        for (final item in [...current.items, ...next.items]) item.id: item,
      };
      _query = nextQuery;
      state = AsyncData(
        AdminCulturePage(
          items: byId.values.toList(),
          currentPage: next.currentPage,
          lastPage: next.lastPage,
          total: next.total,
        ),
      );
    } catch (error, stack) {
      state = AsyncError<AdminCulturePage>(
        error,
        stack,
      ).copyWithPrevious(AsyncData(current));
    } finally {
      _loadingMore = false;
    }
  }
}
