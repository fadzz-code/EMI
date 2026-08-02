import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:emi_mobile/features/culture/data/culture_models.dart';
import 'package:emi_mobile/features/teacher/data/teacher_providers.dart';
import 'package:emi_mobile/features/teacher/data/teacher_repository.dart';
import 'package:emi_mobile/features/teacher/presentation/teacher_culture_screens.dart';
import 'package:emi_mobile/features/teacher/presentation/teacher_dashboard_screen.dart';
import 'package:emi_mobile/shared/widgets/emi_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _Auth extends AuthController {
  _Auth() : super(_MockAuthRepository()) {
    state = const AuthState(status: AuthStatus.authenticatedTeacher);
  }
}

class _UploadRepository extends TeacherRepository {
  _UploadRepository(super.dio, super.mapper, this.requests);

  final List<RequestOptions> requests;

  @override
  Future<String> uploadCulture(String path, String name) async {
    requests.add(RequestOptions(path: '/media', method: 'POST'));
    return 'media-2';
  }
}

TeacherDashboardSummary get _summary => TeacherDashboardSummary.fromJson({
  'class': {'id': 'class-1', 'name': 'Kelas 7A'},
  'students': {},
  'learning': {},
  'recent_activity': [],
});

TeacherClassPage get _classes => TeacherClassPage.fromJson({
  'data': [
    {'id': 'class-1', 'name': 'Kelas 7A', 'status': 'active'},
  ],
  'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
});

CultureItem _item({String status = 'published', String type = 'image'}) =>
    CultureItem.fromJson({
      'id': 'culture-1',
      'class_id': 'class-1',
      'title': 'Tari Lulo',
      'description': 'Budaya Tolaki',
      'content_type': type,
      'display_order': 2,
      'status': status,
      'updated_at': '2026-07-18T09:00:00Z',
      'school_class': {'id': 'class-1', 'name': 'Kelas 7A'},
      'media': type != 'link'
          ? {
              'id': 'media-1',
              'original_name': type == 'pdf' ? 'rahasia.pdf' : 'rahasia.jpg',
              'url':
                  'https://example.test/lulo.${type == 'pdf' ? 'pdf' : 'jpg'}',
            }
          : null,
      'external_url': type == 'link' ? 'https://example.test/budaya' : null,
    });

CulturePage _page(List<CultureItem> items) =>
    CulturePage(items: items, currentPage: 1, lastPage: 1, total: items.length);

Future<GoRouter> _pump(
  WidgetTester tester, {
  required String location,
  required List<Override> overrides,
  double textScale = 1,
}) async {
  await tester.pumpWidget(const SizedBox());
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/teacher/dashboard',
        builder: (_, _) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: '/teacher/culture',
        builder: (_, _) => const TeacherCultureScreen(),
      ),
      GoRoute(
        path: '/teacher/culture/create',
        builder: (_, s) =>
            TeacherCultureFormScreen(classId: s.uri.queryParameters['classId']),
      ),
      GoRoute(
        path: '/teacher/culture/:id/edit',
        builder: (_, s) => TeacherCultureFormScreen(id: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/teacher/culture/:id',
        builder: (_, s) =>
            TeacherCultureDetailScreen(id: s.pathParameters['id']!),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((_) => _Auth()),
        teacherDashboardProvider.overrideWith((_) async => _summary),
        teacherClassesProvider.overrideWith((_, _) async => _classes),
        ...overrides,
      ],
      child: MaterialApp.router(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  return router;
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 50 && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(done(), isTrue);
}

void main() {
  late List<RequestOptions> requests;
  late Dio dio;
  late TeacherRepository repository;

  Map<String, dynamic> culture({String status = 'draft'}) => {
    'id': 'culture-1',
    'class_id': 'class-1',
    'title': 'Tari Lulo',
    'description': 'Budaya Tolaki',
    'content_type': 'image',
    'display_order': 1,
    'status': status,
    'school_class': {'id': 'class-1', 'name': 'Kelas 7A'},
    'media': {
      'id': 'media-1',
      'original_name': 'lulo.jpg',
      'url': 'https://example.test/lulo.jpg',
    },
  };

  setUp(() {
    requests = [];
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests.add(options);
          final status = options.path.endsWith('/publish')
              ? 'published'
              : options.path.endsWith('/archive')
              ? 'archived'
              : 'draft';
          final data = switch (options.path) {
            '/classes/class-1/culture' when options.method == 'GET' => {
              'data': [culture()],
              'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
            },
            '/media' => {
              'data': {'id': 'media-2', 'original_name': 'baru.jpg'},
            },
            _ => {'data': culture(status: status)},
          };
          handler.resolve(Response(requestOptions: options, data: data));
        },
      ),
    );
    repository = TeacherRepository(dio, const DioErrorMapper());
  });

  test('class-scoped list uses exact public API query', () async {
    final page = await repository.culture('class-1');
    expect(page.items.single.title, 'Tari Lulo');
    expect(page.items.single.schoolClass?.name, 'Kelas 7A');
    expect(requests.single.path, '/classes/class-1/culture');
    expect(requests.single.queryParameters, {
      'per_page': 100,
      'sort_by': 'display_order',
      'sort_direction': 'asc',
    });
  });

  test(
    'create and edit payload stay class scoped without class_id body',
    () async {
      final payload = {
        'title': 'Tari Lulo',
        'description': null,
        'content_type': 'link',
        'media_id': null,
        'external_url': 'https://example.test/budaya',
        'display_order': 2,
        'status': 'published',
      };
      await repository.saveCulture(classId: 'class-1', data: payload);
      await repository.saveCulture(
        classId: 'class-1',
        id: 'culture-1',
        data: payload,
      );
      expect(requests[0].method, 'POST');
      expect(requests[0].path, '/classes/class-1/culture');
      expect(requests[1].method, 'PUT');
      expect(requests[1].path, '/class-culture-items/culture-1');
      for (final request in requests) {
        expect((request.data as Map).containsKey('class_id'), isFalse);
        expect(request.data, payload);
      }
    },
  );

  test('retain, replace, and remove media payload contracts', () async {
    await repository.saveCulture(
      classId: 'class-1',
      id: 'culture-1',
      data: {'media_id': 'media-1', 'external_url': null},
    );
    await repository.saveCulture(
      classId: 'class-1',
      id: 'culture-1',
      data: {'media_id': 'media-2', 'external_url': null},
    );
    await repository.saveCulture(
      classId: 'class-1',
      id: 'culture-1',
      data: {'media_id': null, 'external_url': 'https://example.test/link'},
    );
    expect(requests.map((r) => r.data), [
      {'media_id': 'media-1', 'external_url': null},
      {'media_id': 'media-2', 'external_url': null},
      {'media_id': null, 'external_url': 'https://example.test/link'},
    ]);
    expect(requests.where((r) => r.path == '/media'), isEmpty);
  });

  test('public multipart upload uses culture purpose', () async {
    final file = File('${Directory.systemTemp.path}/culture.jpg');
    await file.writeAsBytes([1, 2, 3]);
    try {
      expect(
        await repository.uploadCulture(file.path, 'culture.jpg'),
        'media-2',
      );
      final form = requests.single.data as FormData;
      expect(requests.single.path, '/media');
      expect(
        form.fields,
        contains(
          predicate<MapEntry<String, String>>(
            (entry) => entry.key == 'purpose' && entry.value == 'culture_media',
          ),
        ),
      );
      expect(
        form.fields,
        contains(
          predicate<MapEntry<String, String>>(
            (entry) => entry.key == 'visibility' && entry.value == 'public',
          ),
        ),
      );
      expect(form.files.single.value.filename, 'culture.jpg');
    } finally {
      await file.delete();
    }
  });

  test(
    'detail and publish archive delete use exact action endpoints',
    () async {
      final detail = await repository.cultureDetail('culture-1');
      await repository.publishCulture('culture-1');
      await repository.archiveCulture('culture-1');
      await repository.deleteCulture('culture-1');
      expect(detail.contentUrl, 'https://example.test/lulo.jpg');
      expect(requests.map((r) => '${r.method} ${r.path}'), [
        'GET /class-culture-items/culture-1',
        'POST /class-culture-items/culture-1/publish',
        'POST /class-culture-items/culture-1/archive',
        'DELETE /class-culture-items/culture-1',
      ]);
    },
  );

  testWidgets('drawer orders Budaya after Kuis and navigates', (tester) async {
    final router = await _pump(
      tester,
      location: '/teacher/dashboard',
      overrides: const [],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('teacherMenuButton')));
    await tester.pumpAndSettle();
    final drawer = find.byType(Drawer);
    final quiz = find.descendant(of: drawer, matching: find.text('Kuis'));
    final culture = find.descendant(
      of: drawer,
      matching: find.text('Budaya Mekongga'),
    );
    expect(
      tester.getTopLeft(culture).dy,
      greaterThan(tester.getTopLeft(quiz).dy),
    );
    await tester.ensureVisible(culture);
    await tester.tap(culture);
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.routeInformationProvider.value.uri.path, '/teacher/culture');
  });

  testWidgets('list loading empty error retry and compact exact item', (
    tester,
  ) async {
    final pending = Completer<CulturePage>();
    await _pump(
      tester,
      location: '/teacher/culture',
      overrides: [
        teacherCultureProvider.overrideWith((_, _) => pending.future),
      ],
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await _pump(
      tester,
      location: '/teacher/culture',
      overrides: [
        teacherCultureProvider.overrideWith((_, _) async => _page([])),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum Ada Budaya'), findsOneWidget);
    expect(
      find.text('Tambahkan materi budaya pertama untuk kelas ini.'),
      findsOneWidget,
    );

    var calls = 0;
    await _pump(
      tester,
      location: '/teacher/culture',
      overrides: [
        teacherCultureProvider.overrideWith((_, _) async {
          calls++;
          throw Exception('network');
        }),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Budaya Belum Bisa Dimuat'), findsOneWidget);
    expect(
      find.text('Materi budaya belum bisa dimuat. Silakan coba lagi.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();
    expect(calls, greaterThan(1));

    await _pump(
      tester,
      location: '/teacher/culture',
      textScale: 1.2,
      overrides: [
        teacherCultureProvider.overrideWith((_, _) async => _page([_item()])),
      ],
    );
    await tester.pumpAndSettle();
    expect(
      find.ancestor(of: find.text('Tari Lulo'), matching: find.byType(EmiCard)),
      findsOneWidget,
    );
    expect(find.text('Kelas 7A'), findsOneWidget);
    expect(find.text('Gambar · 18/07/2026'), findsOneWidget);
    expect(find.text('Terbit'), findsOneWidget);
    for (final raw in [
      'culture-1',
      'class-1',
      'media-1',
      'published',
      'null',
    ]) {
      expect(find.textContaining(raw), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail renders exact content without media internals', (
    tester,
  ) async {
    await _pump(
      tester,
      location: '/teacher/culture/culture-1',
      overrides: [
        teacherCultureDetailProvider.overrideWith((_, _) async => _item()),
      ],
    );
    await tester.pumpAndSettle();
    for (final text in [
      'Tari Lulo',
      'Kelas 7A',
      'Budaya Tolaki',
      'Gambar',
      '2',
      'Terbit',
      '18/07/2026',
    ]) {
      expect(find.text(text), findsWidgets);
    }
    for (final raw in ['media-1', 'rahasia.jpg', 'culture-1', 'class-1']) {
      expect(find.textContaining(raw), findsNothing);
    }
  });

  testWidgets('create edit expose archived status and responsive save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await _pump(
      tester,
      location: '/teacher/culture/culture-1/edit',
      textScale: 1.2,
      overrides: [
        teacherCultureDetailProvider.overrideWith(
          (_, _) async => _item(status: 'archived'),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit Budaya Mekongga'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Tari Lulo'), findsOneWidget);
    final formList = find.descendant(
      of: find.byType(Form),
      matching: find.byType(ListView),
    );
    await tester.drag(formList, const Offset(0, -700));
    await tester.pumpAndSettle();
    final status = find.byKey(const ValueKey('status-archived'));
    expect(status, findsOneWidget);
    expect(
      find.descendant(of: status, matching: find.text('Arsip')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(390, 560);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    expect(find.text('Simpan'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('Simpan')).dy,
      lessThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('retain existing media saves without upload', (tester) async {
    await _pump(
      tester,
      location: '/teacher/culture/culture-1/edit',
      overrides: [
        teacherRepositoryProvider.overrideWith((_) => repository),
        teacherCultureDetailProvider.overrideWith((_, _) async => _item()),
        teacherCultureProvider.overrideWith((_, _) async => _page([_item()])),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.path == '/media'), isEmpty);
    final update = requests.firstWhere((r) => r.method == 'PUT');
    expect((update.data as Map)['media_id'], 'media-1');
  });

  testWidgets(
    'picker replacement uploads then updates new media',
    (tester) async {
      final file = File(
        '${Directory.systemTemp.path}/culture-widget-${DateTime.now().microsecondsSinceEpoch}.pdf',
      );
      file.writeAsBytesSync([1, 2, 3]);
      addTearDown(() => file.deleteSync());
      await _pump(
        tester,
        location: '/teacher/culture/culture-1/edit',
        overrides: [
          teacherRepositoryProvider.overrideWith(
            (_) => _UploadRepository(dio, const DioErrorMapper(), requests),
          ),
          teacherCultureDetailProvider.overrideWith(
            (_, _) async => _item(type: 'pdf'),
          ),
          teacherCultureProvider.overrideWith(
            (_, _) async => _page([_item(type: 'pdf')]),
          ),
          teacherCultureFilePickerProvider.overrideWithValue(
            (_) async => PlatformFile(
              name: 'culture-widget.pdf',
              size: 3,
              path: file.path,
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();
      final formList = find.descendant(
        of: find.byType(Form),
        matching: find.byType(ListView),
      );
      await tester.drag(formList, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ganti Media'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Simpan'));
      await _pumpUntil(tester, () => requests.any((r) => r.method == 'PUT'));
      expect(requests.map((r) => r.path), contains('/media'));
      final update = requests.firstWhere((r) => r.method == 'PUT');
      expect((update.data as Map)['media_id'], 'media-2');
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets('switch to Link removes media and back guards dirty form', (
    tester,
  ) async {
    final router = await _pump(
      tester,
      location: '/teacher/culture/culture-1/edit',
      overrides: [
        teacherRepositoryProvider.overrideWith((_) => repository),
        teacherCultureDetailProvider.overrideWith((_, _) async => _item()),
        teacherCultureProvider.overrideWith((_, _) async => _page([_item()])),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gambar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tautan').last);
    await tester.pumpAndSettle();
    final formList = find.descendant(
      of: find.byType(Form),
      matching: find.byType(ListView),
    );
    await tester.drag(formList, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'URL eksternal'),
      'https://example.test/baru',
    );
    await tester.tap(find.byKey(const Key('teacherBackButton')));
    await tester.pumpAndSettle();
    expect(find.text('Buang perubahan?'), findsOneWidget);
    await tester.tap(find.text('Tetap di sini'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Buang perubahan?'), findsOneWidget);
    await tester.tap(find.text('Tetap di sini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    final update = requests.firstWhere((r) => r.method == 'PUT');
    expect((update.data as Map)['media_id'], isNull);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/teacher/culture/culture-1',
    );
  });

  testWidgets('direct detail back falls back to culture list', (tester) async {
    final router = await _pump(
      tester,
      location: '/teacher/culture/culture-1',
      overrides: [
        teacherCultureDetailProvider.overrideWith((_, _) async => _item()),
        teacherCultureProvider.overrideWith((_, _) async => _page([])),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('teacherBackButton')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.routeInformationProvider.value.uri.path, '/teacher/culture');
  });
}
