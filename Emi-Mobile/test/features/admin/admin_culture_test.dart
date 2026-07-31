import 'dart:async';

import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:emi_mobile/app/theme/emi_theme.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/data/admin_culture_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_culture_repository.dart';
import 'package:emi_mobile/features/admin/data/admin_providers.dart';
import 'package:emi_mobile/features/admin/presentation/admin_culture_screens.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/shared/media/media_opener.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('query sends supported filters and pagination', () {
    expect(
      const AdminCultureQuery(
        search: ' tenun ',
        status: 'draft',
        contentType: 'image',
        page: 2,
      ).toQuery(),
      {
        'search': 'tenun',
        'status': 'draft',
        'content_type': 'image',
        'page': 2,
        'per_page': 15,
      },
    );
  });
  test(
    'query omits empty optional filters',
    () => expect(const AdminCultureQuery(search: ' ').toQuery(), {
      'page': 1,
      'per_page': 15,
    }),
  );
  test('page parses pagination', () {
    final page = AdminCulturePage.fromJson({
      'data': [_item()],
      'meta': {'current_page': 1, 'last_page': 2, 'total': 16},
    });
    expect(page.hasMore, isTrue);
    expect(page.total, 16);
  });
  test('item parses actual fields and media metadata', () {
    final item = AdminCultureItem.fromJson(_item());
    expect(item.title, 'Tari Lulo');
    expect(item.mediaName, 'lulo.jpg');
    expect(item.displayOrder, 3);
  });
  test('item retains media ID from actual nested media response', () {
    final json = _item()..remove('media_id');
    (json['media'] as Map<String, dynamic>)['id'] = 'nested-media-id';
    expect(AdminCultureItem.fromJson(json).mediaId, 'nested-media-id');
  });
  test(
    'save payload contains actual fields only',
    () => expect(
      _request().toJson().keys,
      unorderedEquals([
        'title',
        'description',
        'content_type',
        'media_id',
        'external_url',
        'display_order',
        'status',
      ]),
    ),
  );
  test('nullable description and URL serialize safely', () {
    final json = _request(description: '').toJson();
    expect(json['description'], isNull);
    expect(json['external_url'], isNull);
  });
  test('repository list detail create edit action contracts', () async {
    final requests = <RequestOptions>[];
    final repo = _repository(requests);
    await repo.list(const AdminCultureQuery());
    await repo.detail('c1');
    await repo.save(request: _request());
    await repo.save(id: 'c1', request: _request());
    await repo.publish('c1');
    await repo.archive('c1');
    await repo.delete('c1');
    expect(
      requests.map((e) => '${e.method} ${e.path}'),
      containsAll([
        'GET /admin/culture/items',
        'GET /admin/culture/items/c1',
        'POST /admin/culture/items',
        'PUT /admin/culture/items/c1',
        'POST /admin/culture/items/c1/publish',
        'POST /admin/culture/items/c1/archive',
        'DELETE /admin/culture/items/c1',
      ]),
    );
  });
  test('upload uses culture public contract', () async {
    final requests = <RequestOptions>[];
    expect(
      await _repository(
        requests,
      ).upload(path: 'pubspec.yaml', name: 'foto.jpg'),
      'media1',
    );
    final data = requests.single.data as FormData;
    expect(
      data.fields.any(
        (field) => field.key == 'purpose' && field.value == 'culture_media',
      ),
      isTrue,
    );
    expect(
      data.fields.any(
        (field) => field.key == 'visibility' && field.value == 'public',
      ),
      isTrue,
    );
  });
  test('safe error hides server details and ID', () async {
    await expectLater(
      _repository([], error: true).detail('secret-id'),
      throwsA(
        isA<AppError>().having(
          (e) => e.message,
          'message',
          allOf(isNot(contains('SQLSTATE')), isNot(contains('secret-id'))),
        ),
      ),
    );
  });
  test('media opener rejects non-http URLs without launching', () async {
    expect(
      await const ExternalMediaOpener().open('file:///secret/media.mp4'),
      isFalse,
    );
    expect(await const ExternalMediaOpener().open('not a url'), isFalse);
  });
  test('menu label route and prefix active', () {
    expect(AdminFeature.culture.label, 'Budaya Mekongga');
    expect(AdminFeature.culture.isMobileImplemented, isTrue);
    expect(
      '/admin/culture/c1/edit'.startsWith(AdminFeature.culture.route),
      isTrue,
    );
  });

  testWidgets('list shows thumbnail metadata actions without raw values', (
    tester,
  ) async {
    await _pump(tester, '/admin/culture');
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Gambar'), findsOneWidget);
    expect(find.text('Terbit'), findsOneWidget);
    expect(find.text('Diubah 15/07/2026'), findsOneWidget);
    expect(find.text('media-secret'), findsNothing);
    expect(find.text('image'), findsNothing);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);
  });
  testWidgets('search and filter reach backend query', (tester) async {
    final requests = <RequestOptions>[];
    await _pump(tester, '/admin/culture', requests: requests);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tari');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['search'], 'tari');
  });
  testWidgets('detail sections hide media ID and raw enum', (tester) async {
    await _pump(tester, '/admin/culture/c1');
    await tester.pumpAndSettle();
    expect(find.text('Informasi Konten'), findsOneWidget);
    expect(find.text('Media atau Tautan'), findsOneWidget);
    expect(find.byKey(const Key('adminArchive-culture')), findsOneWidget);
    expect(find.byKey(const Key('adminDelete-culture')), findsOneWidget);
    expect(find.text('media-secret'), findsNothing);
    expect(find.text('image'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('audio enables pause while playback future remains active', (
    tester,
  ) async {
    final player = _FakeCultureAudioPlayer();
    await _pump(
      tester,
      '/admin/culture/c1',
      playerFactory: () => player,
      item: _item()
        ..['content_type'] = 'audio'
        ..['media'] = {
          'url': 'https://example.test/audio.mp3',
          'original_name': 'audio.mp3',
        },
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminCultureAudioToggle')));
    await tester.pump();
    expect(player.prepared, isTrue);
    expect(player.playCalls, 1);
    expect(find.byIcon(Icons.pause), findsOneWidget);
    await tester.tap(find.byKey(const Key('adminCultureAudioToggle')));
    await tester.pump();
    expect(player.pauseCalls, 1);
    await tester.pumpWidget(const SizedBox());
    expect(player.disposed, isTrue);
  });
  testWidgets('picker injection cancel preserves form', (tester) async {
    await _pump(tester, '/admin/culture/create', picker: (_) async => null);
    await tester.pumpAndSettle();
    final title = find.widgetWithText(TextFormField, 'Judul');
    final controller = tester.widget<TextFormField>(title).controller!;
    await tester.enterText(title, 'Judul Baru');
    await tester.scrollUntilVisible(
      find.text('Pilih Media'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Pilih Media'));
    await tester.pump();
    expect(controller.text, 'Judul Baru');
  });
  testWidgets('picker preview shows local filename and size', (tester) async {
    await _pump(
      tester,
      '/admin/culture/create',
      picker: (_) async =>
          PlatformFile(name: 'foto.jpg', size: 2048, path: 'missing/foto.jpg'),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Pilih Media'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Pilih Media'));
    await tester.pump();
    expect(find.text('foto.jpg · 2.0 KB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('invalid picker format maps friendly error', (tester) async {
    await _pump(
      tester,
      '/admin/culture/create',
      picker: (_) async =>
          PlatformFile(name: 'virus.exe', size: 10, path: 'virus.exe'),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Pilih Media'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Pilih Media'));
    await tester.pump();
    expect(find.text('Format media tidak didukung.'), findsOneWidget);
  });
  testWidgets('video picker accepts canonical safe formats', (tester) async {
    await _pump(
      tester,
      '/admin/culture/create',
      picker: (_) async => PlatformFile(
        name: 'budaya.mp4',
        size: 2048,
        path: 'missing/budaya.mp4',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Video').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Pilih Media'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Pilih Media'));
    await tester.pump();
    expect(find.text('budaya.mp4 · 2.0 KB'), findsOneWidget);
  });
  testWidgets('dirty back asks before discarding', (tester) async {
    await _pump(tester, '/admin/culture/create');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Judul'),
      'Berubah',
    );
    await tester.tap(find.byKey(const Key('adminBackButton')));
    await tester.pumpAndSettle();
    expect(find.text('Buang perubahan?'), findsOneWidget);
    expect(find.text('Tetap di sini'), findsOneWidget);
  });
  testWidgets('edit retains old media', (tester) async {
    await _pump(tester, '/admin/culture/c1/edit');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ganti Media'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('Media lama dipertahankan jika tidak diganti.'),
      findsOneWidget,
    );
  });
  testWidgets('form status helper and single scroll mount', (tester) async {
    await _pump(tester, '/admin/culture/create');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pump();
    expect(
      find.text(
        'Draft belum terlihat publik. Terbit langsung tersedia bagi pengguna.',
      ),
      findsOneWidget,
    );
    expect(find.byType(ListView), findsOneWidget);
  });
  testWidgets('large text scale produces no exception', (tester) async {
    await _pump(tester, '/admin/culture', scale: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  String initial, {
  List<RequestOptions>? requests,
  AdminCultureFilePicker? picker,
  AdminCultureAudioPlayer Function()? playerFactory,
  Map<String, dynamic>? item,
  double scale = 1,
}) async {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/admin/culture',
        builder: (_, _) => const AdminCultureScreen(),
      ),
      GoRoute(
        path: '/admin/culture/create',
        builder: (_, _) => const AdminCultureFormScreen(),
      ),
      GoRoute(
        path: '/admin/culture/:id/edit',
        builder: (_, s) => AdminCultureFormScreen(id: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/culture/:id',
        builder: (_, s) =>
            AdminCultureDetailScreen(id: s.pathParameters['id']!),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminCultureRepositoryProvider.overrideWithValue(
          _repository(requests ?? [], item: item),
        ),
        authControllerProvider.overrideWith((_) => _FakeAuth()),
        if (picker != null)
          adminCultureFilePickerProvider.overrideWithValue(picker),
        if (playerFactory != null)
          adminCultureAudioPlayerFactoryProvider.overrideWithValue(
            playerFactory,
          ),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: MaterialApp.router(
          theme: EmiTheme.light(),
          routerConfig: router,
        ),
      ),
    ),
  );
}

AdminCultureRepository _repository(
  List<RequestOptions> requests, {
  bool error = false,
  Map<String, dynamic>? item,
}) => AdminCultureRepository(
  Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (error) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 500,
                  data: {'message': 'SQLSTATE secret-id'},
                ),
              ),
            );
          }
          if (options.path == '/media') {
            return handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': {'id': 'media1'},
                },
              ),
            );
          }
          final list =
              options.path == '/admin/culture/items' && options.method == 'GET';
          handler.resolve(
            Response(
              requestOptions: options,
              data: list
                  ? {
                      'data': [item ?? _item()],
                      'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
                    }
                  : {'data': item ?? _item()},
            ),
          );
        },
      ),
    ),
  const DioErrorMapper(),
);
AdminCultureSaveRequest _request({String description = 'Tarian persatuan'}) =>
    AdminCultureSaveRequest(
      title: 'Tari Lulo',
      description: description,
      contentType: 'image',
      mediaId: 'media-secret',
      externalUrl: null,
      displayOrder: 3,
      status: 'published',
    );
Map<String, dynamic> _item() => {
  'id': 'c1',
  'title': 'Tari Lulo',
  'description': 'Tarian persatuan',
  'content_type': 'image',
  'media_id': 'media-secret',
  'media': {
    'url': 'https://example.test/lulo.jpg',
    'original_name': 'lulo.jpg',
    'size_bytes': 2048,
  },
  'external_url': null,
  'display_order': 3,
  'status': 'published',
  'updated_at': '2026-07-15T00:00:00Z',
};

class _FakeCultureAudioPlayer implements AdminCultureAudioPlayer {
  final _states = StreamController<PlayerState>.broadcast();
  bool _prepared = false;
  bool disposed = false;
  int playCalls = 0;
  int pauseCalls = 0;

  @override
  Stream<PlayerState> get playerStateStream => _states.stream;
  @override
  bool get prepared => _prepared;
  @override
  Future<void> prepare(String url) async => _prepared = true;
  @override
  Future<void> play() {
    playCalls++;
    _states.add(PlayerState(true, ProcessingState.ready));
    return Completer<void>().future;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _states.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _states.close();
  }
}

class _FakeAuth extends StateNotifier<AuthState> implements AuthController {
  _FakeAuth()
    : super(
        const AuthState(
          status: AuthStatus.authenticatedAdmin,
          user: SessionUser(
            id: 'admin',
            email: 'admin@test',
            fullName: 'Admin',
            role: UserRole.admin,
            status: 'approved',
          ),
        ),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
