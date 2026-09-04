import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/network/network_status_controller.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:emi_mobile/features/dictionary/data/offline_dictionary_repository.dart';
import 'package:emi_mobile/features/dictionary/presentation/dictionary_offline_providers.dart';
import 'package:emi_mobile/features/modules/data/offline_module_repository.dart';
import 'package:emi_mobile/features/modules/data/student_module.dart';
import 'package:emi_mobile/features/modules/presentation/student_module_offline_providers.dart';
import 'package:emi_mobile/features/modules/presentation/student_module_ui_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ModuleRepository extends Mock implements OfflineModuleRepository {}

class _DictionaryRepository extends Mock
    implements OfflineDictionaryRepository {}

class _Auth extends StateNotifier<AuthState> implements AuthController {
  _Auth()
    : super(
        const AuthState(
          status: AuthStatus.authenticatedStudent,
          user: SessionUser(
            id: 'student',
            email: 'student@emi.test',
            fullName: 'Student',
            role: UserRole.student,
            status: 'active',
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ModuleRepository modules;
  late _DictionaryRepository dictionaries;
  late ProviderContainer container;

  setUp(() {
    modules = _ModuleRepository();
    dictionaries = _DictionaryRepository();
    container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((_) => _Auth()),
        offlineModuleRepositoryProvider.overrideWith((_) async => modules),
        offlineDictionaryRepositoryProvider.overrideWith(
          (_) async => dictionaries,
        ),
        networkStatusControllerProvider.overrideWith(
          (_) =>
              NetworkStatusController(connectivity: Connectivity(), dio: Dio()),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('module and dictionary provider graphs coexist without cycle', () async {
    when(
      () => modules.local('student', 'module'),
    ).thenAnswer((_) async => null);
    when(
      () => dictionaries.installedCategories('student'),
    ).thenAnswer((_) async => <String>{});

    final module = container.listen(
      studentModuleOfflineStateProvider('module'),
      (_, _) {},
      fireImmediately: true,
    );
    final dictionary = container.listen(
      dictionaryPackageStateProvider('category'),
      (_, _) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(module.read().valueOrNull?.status, ModuleOfflineStatus.download);
    expect(
      dictionary.read().valueOrNull?.status,
      DictionaryPackageStatus.download,
    );
  });

  test('module failure resets state and retry succeeds', () async {
    var attempts = 0;
    when(
      () => modules.local('student', 'module'),
    ).thenAnswer((_) async => null);
    when(() => modules.download('student', 'module')).thenAnswer((_) async {
      if (attempts++ == 0) throw const SocketException('raw socket failure');
      return _modulePackage;
    });
    final states = <ModuleOfflineStatus>[];
    container.listen(studentModuleOfflineStateProvider('module'), (_, next) {
      final status = next.valueOrNull?.status;
      if (status != null) states.add(status);
    }, fireImmediately: true);
    final controller = container.read(studentModuleOfflineControllerProvider);

    await expectLater(controller.download('module'), throwsA(anything));
    await controller.download('module');
    await Future<void>.delayed(Duration.zero);

    expect(states, contains(ModuleOfflineStatus.retry));
    expect(states.last, ModuleOfflineStatus.availableOffline);
    verify(() => modules.download('student', 'module')).called(2);
  });

  test('dictionary failure resets state and retry succeeds', () async {
    var attempts = 0;
    when(
      () => dictionaries.installedCategories('student'),
    ).thenAnswer((_) async => <String>{});
    when(
      () => dictionaries.download('student', 'category', includeAudio: false),
    ).thenAnswer((_) async {
      if (attempts++ == 0) throw const FormatException('raw parser failure');
      return _dictionaryPackage;
    });
    final states = <DictionaryPackageStatus>[];
    container.listen(dictionaryPackageStateProvider('category'), (_, next) {
      final status = next.valueOrNull?.status;
      if (status != null) states.add(status);
    }, fireImmediately: true);
    final controller = container.read(dictionaryPackageControllerProvider);

    await expectLater(
      controller.download('category', includeAudio: false),
      throwsA(anything),
    );
    await controller.download('category', includeAudio: false);
    await Future<void>.delayed(Duration.zero);

    expect(states, contains(DictionaryPackageStatus.retry));
    expect(states.last, DictionaryPackageStatus.availableOffline);
    verify(
      () => dictionaries.download('student', 'category', includeAudio: false),
    ).called(2);
  });

  test('download errors map to Indonesian messages without raw exception', () {
    final values = <Object>[
      const AppError(type: AppErrorType.networkUnavailable, message: 'raw'),
      const AppError(type: AppErrorType.timeout, message: 'raw'),
      const AppError(type: AppErrorType.server, message: 'raw'),
      const AppError(type: AppErrorType.unauthorized, message: 'raw'),
      const FormatException('raw'),
      StateError('raw'),
      Exception("Instance of 'CircularDependencyError'"),
    ].map(offlineDownloadErrorMessage);

    expect(values, everyElement(isNot(contains('raw'))));
    expect(values, everyElement(isNot(contains('Exception'))));
    expect(values, everyElement(isNot(contains('CircularDependencyError'))));
  });
}

final _modulePackage = OfflineModulePackage(
  module: const StudentModule(
    id: 'module',
    title: 'Module',
    status: 'published',
    sortOrder: 1,
    progress: ModuleProgress(
      status: 'not_started',
      progressPercent: 0,
      completedLessons: 0,
      totalLessons: 0,
    ),
    lessons: [],
  ),
  version: 'v1',
  downloadedAt: DateTime(2026),
);

final _dictionaryPackage = OfflineDictionaryPackage(
  categoryId: 'category',
  version: 'v1',
  downloadedAt: DateTime(2026),
  entryCount: 1,
);
