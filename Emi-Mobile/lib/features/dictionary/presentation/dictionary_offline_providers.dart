import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/network/network_status_controller.dart';
import '../../../core/offline/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/dictionary_entry.dart';
import '../data/dictionary_providers.dart';
import '../data/offline_dictionary_repository.dart';

enum DictionaryPackageStatus {
  download,
  downloading,
  availableOffline,
  updateAvailable,
  retry,
}

class DictionaryPackageState {
  const DictionaryPackageState(this.status, {this.isNew = false});

  final DictionaryPackageStatus status;
  final bool isNew;
}

final dictionaryNetworkModeProvider = Provider<NetworkMode>(
  (ref) => ref.watch(networkStatusControllerProvider).mode,
);

final offlineDictionaryRepositoryProvider =
    Provider<Future<OfflineDictionaryRepository>>((ref) async {
      final database = await ref.watch(offlineDatabaseProvider);
      final fileStore = await ref.watch(offlineFileStoreProvider);
      final dio = ref.watch(dioProvider);
      final remote = ref.watch(dictionaryRepositoryProvider);
      return OfflineDictionaryRepository(
        database: database,
        fileStore: fileStore,
        dio: dio,
        remote: remote,
      );
    });

final dictionaryCategoriesProvider =
    FutureProvider.autoDispose<List<DictionaryCategory>>((ref) async {
      final categories = await ref
          .watch(dictionaryRepositoryProvider)
          .categories();
      await ref
          .read(dictionaryPackageControllerProvider)
          .displayManifestSnapshot(categories.map((value) => value.id).toSet());
      return categories;
    });

final dictionaryPackageControllerProvider =
    Provider<DictionaryPackageController>((ref) {
      final controller = DictionaryPackageController(ref);
      ref.onDispose(controller.dispose);
      return controller;
    });

final dictionaryPackageStateProvider = StreamProvider.autoDispose
    .family<DictionaryPackageState, String>(
      (ref, categoryId) =>
          ref.watch(dictionaryPackageControllerProvider).watch(categoryId),
    );

final integratedDictionaryListProvider = FutureProvider.autoDispose
    .family<DictionaryPage, DictionaryQuery>((ref, query) async {
      final owner = ref.watch(authControllerProvider).user?.id;
      if (owner == null) return ref.watch(dictionaryListProvider(query).future);
      return (await ref.watch(offlineDictionaryRepositoryProvider)).list(
        owner,
        search: query.search,
        language: query.language,
        categoryId: query.categoryId,
        page: query.page,
      );
    });

final integratedDictionaryDetailProvider = FutureProvider.autoDispose
    .family<DictionaryEntry, String>((ref, id) async {
      final owner = ref.watch(authControllerProvider).user?.id;
      if (owner == null) return ref.watch(dictionaryDetailProvider(id).future);
      return (await ref.watch(
        offlineDictionaryRepositoryProvider,
      )).detail(owner, id);
    });

class DictionaryAudioQuery {
  const DictionaryAudioQuery({required this.id, required this.remoteUrl});

  final String id;
  final String remoteUrl;

  @override
  bool operator ==(Object other) =>
      other is DictionaryAudioQuery &&
      other.id == id &&
      other.remoteUrl == remoteUrl;

  @override
  int get hashCode => Object.hash(id, remoteUrl);
}

final dictionaryAudioSourceProvider = FutureProvider.autoDispose
    .family<String?, DictionaryAudioQuery>((ref, query) async {
      final mode = ref.watch(dictionaryNetworkModeProvider);
      if (mode == NetworkMode.online) return query.remoteUrl;
      final owner = ref.watch(authControllerProvider).user?.id;
      if (owner == null) return null;
      return (await ref.watch(
        offlineDictionaryRepositoryProvider,
      )).localAudioUrl(owner, query.id);
    });

class DictionaryPackageController {
  DictionaryPackageController(this._ref);

  final Ref _ref;
  final _states = <String, StreamController<DictionaryPackageState>>{};
  final _loads = <String, Future<void>>{};
  final _downloads = <String, Future<void>>{};
  final _newByOwner = <String, Set<String>>{};

  String? get _owner => _ref.read(authControllerProvider).user?.id;

  Stream<DictionaryPackageState> watch(String categoryId) {
    final owner = _owner;
    if (owner == null) {
      return Stream.value(
        const DictionaryPackageState(DictionaryPackageStatus.download),
      );
    }
    final controller = _states.putIfAbsent(
      '$owner:$categoryId',
      StreamController.broadcast,
    );
    _loads.putIfAbsent(
      '$owner:$categoryId',
      () => _load(owner, categoryId, controller),
    );
    return controller.stream;
  }

  Future<void> _load(
    String owner,
    String categoryId,
    StreamController<DictionaryPackageState> state,
  ) async {
    try {
      final repository = await _ref.read(offlineDictionaryRepositoryProvider);
      final installed = await repository.installedCategories(owner);
      var status = installed.contains(categoryId)
          ? DictionaryPackageStatus.availableOffline
          : DictionaryPackageStatus.download;
      if (_ref.read(networkStatusControllerProvider).mode ==
          NetworkMode.online) {
        final manifest = await repository.manifest();
        await repository.reconcileManifest(owner, manifest);
        if (installed.contains(categoryId) &&
            (await repository.updateAvailable(
              owner,
              authoritativeManifest: manifest,
            )).contains(categoryId)) {
          status = DictionaryPackageStatus.updateAvailable;
        }
      }
      state.add(
        DictionaryPackageState(
          status,
          isNew: _newByOwner[owner]?.contains(categoryId) == true,
        ),
      );
    } catch (_) {
      state.add(const DictionaryPackageState(DictionaryPackageStatus.retry));
    }
  }

  Future<void> displayManifestSnapshot(Set<String> displayedCategoryIds) async {
    final owner = _owner;
    if (owner == null || _newByOwner.containsKey(owner)) return;
    final repository = await _ref.read(offlineDictionaryRepositoryProvider);
    final manifest = await repository.manifest();
    await repository.reconcileManifest(owner, manifest);
    final serverIds = manifest.map((value) => value.categoryId).toSet();
    final displayed = serverIds.intersection(displayedCategoryIds);
    final seen = await repository.seenManifestCategories(owner);
    _newByOwner[owner] = displayed.difference(seen);
    await repository.markManifestSeen(owner, displayed);
  }

  Future<bool> includeAudioDefault(String categoryId) async {
    final owner = _owner;
    if (owner == null) return false;
    return (await _ref.read(
      offlineDictionaryRepositoryProvider,
    )).packageIncludesAudio(owner, categoryId);
  }

  Future<void> download(String categoryId, {required bool includeAudio}) async {
    final owner = _owner;
    if (owner == null) return;
    final key = '$owner:$categoryId';
    final existing = _downloads[key];
    if (existing != null) return existing;
    final future = _download(owner, categoryId, includeAudio: includeAudio);
    _downloads[key] = future;
    try {
      await future;
    } finally {
      if (identical(_downloads[key], future)) _downloads.remove(key);
    }
  }

  Future<void> _download(
    String owner,
    String categoryId, {
    required bool includeAudio,
  }) async {
    final state = _states.putIfAbsent(
      '$owner:$categoryId',
      StreamController.broadcast,
    );
    state.add(
      const DictionaryPackageState(DictionaryPackageStatus.downloading),
    );
    try {
      await (await _ref.read(
        offlineDictionaryRepositoryProvider,
      )).download(owner, categoryId, includeAudio: includeAudio);
      state.add(
        const DictionaryPackageState(DictionaryPackageStatus.availableOffline),
      );
    } catch (error, stackTrace) {
      debugPrint('Offline dictionary download failed: $error\n$stackTrace');
      if (error.toString().contains('berubah saat diunduh')) {
        _ref.invalidate(dictionaryCategoriesProvider);
      }
      state.add(const DictionaryPackageState(DictionaryPackageStatus.retry));
      rethrow;
    }
  }

  Future<void> remove(String categoryId) async {
    final owner = _owner;
    if (owner == null) return;
    await (await _ref.read(
      offlineDictionaryRepositoryProvider,
    )).remove(owner, categoryId);
    _states['$owner:$categoryId']?.add(
      const DictionaryPackageState(DictionaryPackageStatus.download),
    );
  }

  void dispose() {
    for (final state in _states.values) {
      state.close();
    }
  }
}
