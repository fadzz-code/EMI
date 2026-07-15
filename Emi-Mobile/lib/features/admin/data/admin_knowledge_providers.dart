import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_knowledge_repository.dart';

final adminKnowledgeRepositoryProvider = Provider<AdminKnowledgeRepository>(
  (ref) =>
      AdminKnowledgeRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final adminKnowledgeSummaryProvider = FutureProvider<AdminKnowledgeSummary>(
  (ref) => ref.watch(adminKnowledgeRepositoryProvider).summary(),
);

final adminKnowledgeProvider =
    AsyncNotifierProvider<AdminKnowledgeController, AdminKnowledgePage>(
      AdminKnowledgeController.new,
    );

final adminKnowledgeDetailProvider =
    FutureProvider.family<AdminKnowledgeItem, String>(
      (ref, id) => ref.watch(adminKnowledgeRepositoryProvider).detail(id),
    );

class AdminKnowledgeController extends AsyncNotifier<AdminKnowledgePage> {
  AdminKnowledgeQuery _query = const AdminKnowledgeQuery();
  int _request = 0;

  AdminKnowledgeQuery get query => _query;

  @override
  Future<AdminKnowledgePage> build() => _load(_query);

  Future<AdminKnowledgePage> _load(AdminKnowledgeQuery query) =>
      ref.read(adminKnowledgeRepositoryProvider).list(query);

  Future<void> search(String value) async {
    _query = _query.copyWith(search: value, page: 1);
    final request = ++_request;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() => _load(_query));
    if (request == _request) state = next;
  }

  Future<void> filter({
    String? category,
    String? sourceType,
    String? status,
  }) async {
    _query = _query.copyWith(
      category: category,
      sourceType: sourceType,
      status: status,
      clearCategory: category == null,
      clearSourceType: sourceType == null,
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
      AdminKnowledgePage(
        items: byId.values.toList(),
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
      ),
    );
  }
}
