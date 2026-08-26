import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/network/network_status_controller.dart';
import '../../../core/offline/providers.dart';
import '../../../core/offline/sync_executor.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../data/offline_module_repository.dart';
import '../data/student_module.dart';
import '../data/student_module_providers.dart';
import '../data/student_module_repository.dart';
import 'student_module_ui_controller.dart';

final offlineModuleRepositoryProvider =
    Provider<Future<OfflineModuleRepository>>(
      (ref) async => OfflineModuleRepository(
        database: await ref.watch(offlineDatabaseProvider),
        fileStore: await ref.watch(offlineFileStoreProvider),
        dio: ref.watch(dioProvider),
        remote: ref.watch(studentModuleRepositoryProvider),
      ),
    );

final syncExecutorProvider = Provider<Future<SyncExecutor>>(
  (ref) async => SyncExecutor(
    queue: await ref.watch(syncQueueProvider),
    sender: _Sender(ref.watch(studentModuleRepositoryProvider)),
  ),
);

final offlineStudentModuleDetailProvider = FutureProvider.autoDispose
    .family<StudentModule, String>((ref, moduleId) async {
      final auth = ref.watch(authControllerProvider);
      final owner = auth.user?.id;
      if (owner == null) {
        return ref.watch(studentModuleDetailProvider(moduleId).future);
      }
      final mode = ref.watch(networkStatusControllerProvider).mode;
      return (await ref.watch(
        offlineModuleRepositoryProvider,
      )).detail(owner, moduleId, allowFallback: mode != NetworkMode.online);
    });

final offlineStudentLessonDetailProvider = FutureProvider.autoDispose
    .family<StudentLesson, String>((ref, lessonId) async {
      final auth = ref.watch(authControllerProvider);
      final owner = auth.user?.id;
      if (owner == null) {
        return ref.watch(studentLessonDetailProvider(lessonId).future);
      }
      final mode = ref.watch(networkStatusControllerProvider).mode;
      return (await ref.watch(
        offlineModuleRepositoryProvider,
      )).lesson(owner, lessonId, allowFallback: mode != NetworkMode.online);
    });

final offlineStudentLessonContentProvider = FutureProvider.autoDispose
    .family<LessonContent?, String>((ref, lessonId) async {
      final auth = ref.watch(authControllerProvider);
      final owner = auth.user?.id;
      if (owner == null) {
        return ref.watch(studentLessonContentProvider(lessonId).future);
      }
      final mode = ref.watch(networkStatusControllerProvider).mode;
      return (await ref.watch(
        offlineModuleRepositoryProvider,
      )).content(owner, lessonId, allowFallback: mode != NetworkMode.online);
    });

final moduleSyncCoordinatorProvider = Provider<ModuleSyncCoordinator>((ref) {
  final coordinator = ModuleSyncCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

class ModuleSyncCoordinator {
  ModuleSyncCoordinator(this._ref) {
    _ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      if (next.status == AuthStatus.authenticatedStudent &&
          previous?.status != AuthStatus.authenticatedStudent &&
          next.user != null) {
        await (await _ref.read(syncQueueProvider)).unblockOwner(next.user!.id);
      }
      await trigger(next: next);
    });
    _ref.listen<NetworkStatusController>(networkStatusControllerProvider, (
      _,
      next,
    ) {
      if (next.mode == NetworkMode.online) trigger();
    });
    trigger();
  }

  final Ref _ref;
  bool _disposed = false;

  Future<void> trigger({AuthState? next}) async {
    if (_disposed) return;
    final AuthState auth = next ?? _ref.read(authControllerProvider);
    final owner = auth.status == AuthStatus.authenticatedStudent
        ? auth.user?.id
        : null;
    if (owner == null ||
        _ref.read(networkStatusControllerProvider).mode != NetworkMode.online) {
      return;
    }
    await (await _ref.read(syncExecutorProvider)).run(owner);
  }

  void dispose() => _disposed = true;
}

class IntegratedStudentModuleOfflineController
    implements StudentModuleOfflineController {
  IntegratedStudentModuleOfflineController(this._ref);
  final Ref _ref;
  final _states = <String, StreamController<ModuleOfflineState>>{};

  String get _owner {
    final owner = _ref.read(authControllerProvider).user?.id;
    if (owner == null) throw StateError('Siswa belum terautentikasi.');
    return owner;
  }

  @override
  Stream<ModuleOfflineState> watch(String moduleId) {
    final owner = _ref.read(authControllerProvider).user?.id;
    if (owner == null) {
      return Stream.value(
        const ModuleOfflineState(ModuleOfflineStatus.download),
      );
    }
    final key = '$owner:$moduleId';
    final controller = _states.putIfAbsent(
      key,
      () => StreamController.broadcast(),
    );
    () async {
      final repository = await _ref.read(offlineModuleRepositoryProvider);
      final local = await repository.local(owner, moduleId);
      controller.add(
        ModuleOfflineState(
          local == null
              ? ModuleOfflineStatus.download
              : ModuleOfflineStatus.availableOffline,
        ),
      );
      if (local != null &&
          _ref.read(networkStatusControllerProvider).mode ==
              NetworkMode.online) {
        final updates = await repository.updates(owner);
        if (updates.any((value) => value.moduleId == moduleId)) {
          controller.add(
            const ModuleOfflineState(ModuleOfflineStatus.updateAvailable),
          );
        }
      }
    }();
    return controller.stream;
  }

  @override
  Future<void> download(String moduleId) async {
    final owner = _owner;
    final state = _states.putIfAbsent(
      '$owner:$moduleId',
      () => StreamController.broadcast(),
    );
    state.add(const ModuleOfflineState(ModuleOfflineStatus.downloading));
    try {
      await (await _ref.read(
        offlineModuleRepositoryProvider,
      )).download(owner, moduleId);
      state.add(const ModuleOfflineState(ModuleOfflineStatus.availableOffline));
    } catch (_) {
      state.add(const ModuleOfflineState(ModuleOfflineStatus.retry));
      rethrow;
    }
  }

  @override
  Future<void> remove(String moduleId) async {
    final owner = _owner;
    await (await _ref.read(
      offlineModuleRepositoryProvider,
    )).remove(owner, moduleId);
    _states['$owner:$moduleId']?.add(
      const ModuleOfflineState(ModuleOfflineStatus.download),
    );
  }
}

class IntegratedStudentLessonCompletionController
    implements StudentLessonCompletionController {
  IntegratedStudentLessonCompletionController(this._ref);
  final Ref _ref;
  final _states = <String, StreamController<LessonCompletionSyncStatus>>{};

  String get _owner {
    final owner = _ref.read(authControllerProvider).user?.id;
    if (owner == null) throw StateError('Siswa belum terautentikasi.');
    return owner;
  }

  @override
  Stream<LessonCompletionSyncStatus> watch(String lessonId) {
    final owner = _ref.read(authControllerProvider).user?.id;
    if (owner == null) return Stream.value(LessonCompletionSyncStatus.idle);
    final controller = _states.putIfAbsent(
      '$owner:$lessonId',
      () => StreamController.broadcast(),
    );
    () async {
      final rows = await (await _ref.read(syncQueueProvider)).database.query(
        'sync_queue',
        where: 'owner_student_id = ? AND operation_type = ? AND entity_id = ?',
        whereArgs: [owner, 'lesson_completed', lessonId],
        limit: 1,
      );
      controller.add(
        rows.isEmpty
            ? LessonCompletionSyncStatus.idle
            : LessonCompletionSyncStatus.pending,
      );
    }();
    return controller.stream;
  }

  @override
  Future<void> complete(String lessonId) async {
    final owner = _owner;
    final queue = await _ref.read(syncQueueProvider);
    await queue.enqueue(
      ownerStudentId: owner,
      operationType: 'lesson_completed',
      entityId: lessonId,
      payload: {'lesson_id': lessonId},
    );
    final state = _states.putIfAbsent(
      '$owner:$lessonId',
      () => StreamController.broadcast(),
    );
    state.add(LessonCompletionSyncStatus.pending);
    if (_ref.read(networkStatusControllerProvider).mode == NetworkMode.online) {
      await (await _ref.read(syncExecutorProvider)).run(owner);
      final remaining = await queue.database.query(
        'sync_queue',
        where: 'owner_student_id = ? AND entity_id = ?',
        whereArgs: [owner, lessonId],
        limit: 1,
      );
      state.add(
        remaining.isEmpty
            ? LessonCompletionSyncStatus.synced
            : LessonCompletionSyncStatus.pending,
      );
    }
  }
}

class _Sender implements LessonCompletionSender {
  const _Sender(this.repository);
  final StudentModuleRepository repository;
  @override
  Future<void> completeLesson(String lessonId) async {
    await repository.completeLesson(lessonId);
  }
}
