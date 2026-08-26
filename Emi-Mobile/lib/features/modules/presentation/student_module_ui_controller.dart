import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'student_module_offline_providers.dart';

enum ModuleOfflineStatus {
  download,
  downloading,
  availableOffline,
  updateAvailable,
  retry,
}

class ModuleOfflineState {
  const ModuleOfflineState(this.status, {this.progress});

  final ModuleOfflineStatus status;
  final double? progress;
}

abstract interface class StudentModuleOfflineController {
  Stream<ModuleOfflineState> watch(String moduleId);
  Future<void> download(String moduleId);
  Future<void> remove(String moduleId);
}

class UnsupportedStudentModuleOfflineController
    implements StudentModuleOfflineController {
  const UnsupportedStudentModuleOfflineController();

  @override
  Stream<ModuleOfflineState> watch(String moduleId) =>
      Stream.value(const ModuleOfflineState(ModuleOfflineStatus.download));

  @override
  Future<void> download(String moduleId) =>
      Future.error(UnsupportedError('Download offline belum tersedia.'));

  @override
  Future<void> remove(String moduleId) =>
      Future.error(UnsupportedError('Penyimpanan offline belum tersedia.'));
}

final studentModuleOfflineControllerProvider =
    Provider<StudentModuleOfflineController>(
      (ref) => IntegratedStudentModuleOfflineController(ref),
    );

final studentModuleOfflineStateProvider = StreamProvider.autoDispose
    .family<ModuleOfflineState, String>(
      (ref, moduleId) =>
          ref.watch(studentModuleOfflineControllerProvider).watch(moduleId),
    );

enum LessonCompletionSyncStatus { idle, pending, synced }

abstract interface class StudentLessonCompletionController {
  Stream<LessonCompletionSyncStatus> watch(String lessonId);
  Future<void> complete(String lessonId);
}

final studentLessonCompletionControllerProvider =
    Provider<StudentLessonCompletionController>(
      (ref) => IntegratedStudentLessonCompletionController(ref),
    );

final studentLessonCompletionStateProvider = StreamProvider.autoDispose
    .family<LessonCompletionSyncStatus, String>(
      (ref, lessonId) =>
          ref.watch(studentLessonCompletionControllerProvider).watch(lessonId),
    );
