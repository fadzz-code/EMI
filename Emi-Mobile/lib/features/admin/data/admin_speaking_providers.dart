import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_speaking_repository.dart';

final adminSpeakingRepositoryProvider = Provider<AdminSpeakingRepository>(
  (ref) =>
      AdminSpeakingRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final adminSpeakingTemplatesProvider =
    AsyncNotifierProvider<AdminSpeakingController, AdminSpeakingPage>(
      AdminSpeakingController.new,
    );

final adminSpeakingDetailProvider =
    FutureProvider.family<AdminSpeakingTemplate, String>(
      (ref, id) => ref.watch(adminSpeakingRepositoryProvider).detail(id),
    );

class AdminSpeakingController extends AsyncNotifier<AdminSpeakingPage> {
  AdminSpeakingQuery _query = const AdminSpeakingQuery();
  int _request = 0;

  AdminSpeakingQuery get query => _query;

  @override
  Future<AdminSpeakingPage> build() => _load(_query);

  Future<AdminSpeakingPage> _load(AdminSpeakingQuery query) =>
      ref.read(adminSpeakingRepositoryProvider).list(query);

  Future<void> search(String value) async {
    _query = _query.copyWith(search: value, page: 1);
    await _replace();
  }

  Future<void> filter(String? status) async {
    _query = _query.copyWith(
      status: status,
      clearStatus: status == null,
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
    if (current == null || !current.hasMore || state.isLoading) return;
    final nextQuery = _query.copyWith(page: current.currentPage + 1);
    final next = await _load(nextQuery);
    _query = nextQuery;
    state = AsyncData(
      AdminSpeakingPage(
        items: [...current.items, ...next.items],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
        total: next.total,
      ),
    );
  }
}
