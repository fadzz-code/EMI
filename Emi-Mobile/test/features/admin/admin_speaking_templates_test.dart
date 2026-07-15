import 'package:dio/dio.dart';
import 'package:emi_mobile/app/theme/emi_theme.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/data/admin_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_speaking_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_speaking_repository.dart';
import 'package:emi_mobile/features/admin/presentation/admin_speaking_screens.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('query trims search and sends status pagination', () {
    expect(
      const AdminSpeakingQuery(
        search: ' salam ',
        status: 'published',
        page: 2,
      ).toQuery(),
      {'search': 'salam', 'status': 'published', 'page': 2, 'per_page': 15},
    );
  });

  test('page parses list and pagination', () {
    final page = AdminSpeakingPage.fromJson({
      'data': [_template()],
      'meta': {'current_page': 1, 'last_page': 2, 'total': 16},
    });
    expect(page.items.single.targetText, 'Mepokoaso');
    expect(page.hasMore, isTrue);
    expect(page.total, 16);
  });

  test(
    'repository list detail create edit publish archive contracts',
    () async {
      final requests = <RequestOptions>[];
      final repository = _repository(requests: requests);
      await repository.list(
        const AdminSpeakingQuery(search: 'salam', status: 'draft'),
      );
      await repository.detail('s1');
      await repository.save(request: _request('draft'));
      await repository.save(id: 's1', request: _request('published'));
      await repository.archive('s1');
      expect(
        requests.map((e) => '${e.method} ${e.path}'),
        containsAll([
          'GET /admin/speaking/exercises',
          'GET /admin/speaking/exercises/s1',
          'POST /admin/speaking/exercises',
          'PATCH /admin/speaking/exercises/s1',
          'PATCH /admin/speaking/exercises/s1/archive',
        ]),
      );
      expect((requests[3].data as Map)['status'], 'published');
    },
  );

  test('upload uses speaking public media contract', () async {
    final requests = <RequestOptions>[];
    expect(
      await _repository(
        requests: requests,
      ).uploadAudio(path: 'pubspec.yaml', name: 'contoh.mp3'),
      'media1',
    );
    final data = requests.single.data as FormData;
    expect(
      data.fields.any(
        (e) => e.key == 'purpose' && e.value == 'speaking_reference_audio',
      ),
      isTrue,
    );
    expect(
      data.fields.any((e) => e.key == 'visibility' && e.value == 'public'),
      isTrue,
    );
  });

  test('detail gets temporary URL only when public URL absent', () async {
    final requests = <RequestOptions>[];
    final item = await _repository(
      requests: requests,
      publicAudio: false,
    ).detail('s1');
    expect(item.referenceAudioUrl, 'https://example.test/temporary.mp3');
    expect(
      requests.map((e) => e.path),
      contains('/media/old-media/temporary-url'),
    );
  });

  test('detail skips temporary URL when public URL exists', () async {
    final requests = <RequestOptions>[];
    await _repository(requests: requests).detail('s1');
    expect(requests.where((e) => e.path.contains('temporary-url')), isEmpty);
  });

  test('retain and clear audio payload semantics', () {
    expect(_request('draft').toJson()['reference_audio_media_id'], 'old-media');
    expect(
      _request('draft', audioId: null).toJson(),
      containsPair('reference_audio_media_id', null),
    );
  });

  test('safe error mapping hides server exception and IDs', () async {
    final repository = _repository(error: true);
    await expectLater(
      repository.detail('secret-id'),
      throwsA(
        isA<AppError>().having(
          (e) => e.message,
          'message',
          allOf(isNot(contains('secret-id')), isNot(contains('SQLSTATE'))),
        ),
      ),
    );
  });

  test('menu feature label and prefix route are speaking template', () {
    expect(AdminFeature.speaking.label, 'Template Speaking');
    expect(
      '/admin/speaking/s1/edit'.startsWith(AdminFeature.speaking.route),
      isTrue,
    );
    expect(AdminFeature.speaking.isMobileImplemented, isTrue);
  });

  testWidgets(
    'list mounts real screen with search, metadata, actions, and no raw media ID',
    (tester) async {
      await _pump(tester, initial: '/admin/speaking');
      await tester.pumpAndSettle();
      expect(find.text('Cari judul atau kalimat latihan'), findsOneWidget);
      expect(find.textContaining('Audio tersedia'), findsOneWidget);
      expect(find.textContaining('Diubah 15/07/2026'), findsOneWidget);
      expect(find.text('old-media'), findsNothing);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Lihat'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Arsipkan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('draft list exposes publish action', (tester) async {
    await _pump(tester, initial: '/admin/speaking', status: 'draft');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Terbitkan'), findsOneWidget);
  });

  testWidgets('list search and filter drive backend query', (tester) async {
    final requests = <RequestOptions>[];
    await _pump(tester, initial: '/admin/speaking', requests: requests);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'kalimat');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['search'], 'kalimat');
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terbit').last);
    final apply = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Terapkan'),
    );
    apply.onPressed!();
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['status'], 'published');
  });

  testWidgets('pagination loads next backend page', (tester) async {
    final requests = <RequestOptions>[];
    await _pump(
      tester,
      initial: '/admin/speaking',
      requests: requests,
      lastPage: 2,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muat Lagi'));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['page'], 2);
  });

  testWidgets('detail shows hierarchy preview controls and no raw ID', (
    tester,
  ) async {
    await _pump(tester, initial: '/admin/speaking/s1');
    await tester.pumpAndSettle();
    expect(find.text('Kalimat Latihan'), findsOneWidget);
    expect(find.text('Panduan'), findsOneWidget);
    expect(find.text('Audio Referensi'), findsOneWidget);
    expect(find.text('Putar'), findsOneWidget);
    expect(find.text('Jeda'), findsOneWidget);
    expect(find.text('Berhenti'), findsOneWidget);
    expect(find.text('old-media'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit retains old audio and picker cancel preserves form', (
    tester,
  ) async {
    await _pump(
      tester,
      initial: '/admin/speaking/s1/edit',
      picker: () async => null,
    );
    await tester.pumpAndSettle();
    final title = find.widgetWithText(TextFormField, 'Salam');
    final titleController = tester.widget<TextFormField>(title).controller!;
    await tester.enterText(title, 'Salam Baru');
    tester.testTextInput.hide();
    final replace = find.widgetWithText(FilledButton, 'Ganti Audio');
    await tester.scrollUntilVisible(
      replace,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    tester.widget<FilledButton>(replace).onPressed!();
    await tester.pumpAndSettle();
    expect(titleController.text, 'Salam Baru');
    expect(find.text('Ganti Audio'), findsOneWidget);
  });

  testWidgets('injectable picker validates unsafe audio', (tester) async {
    await _pump(
      tester,
      initial: '/admin/speaking/create',
      picker: () async =>
          PlatformFile(name: 'virus.exe', size: 10, path: 'virus.exe'),
    );
    await tester.pumpAndSettle();
    final pick = find.widgetWithText(FilledButton, 'Pilih Audio');
    await tester.scrollUntilVisible(
      pick,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(pick);
    await tester.pump();
    expect(find.text('Format audio tidak didukung.'), findsOneWidget);
  });

  testWidgets('create form hierarchy status helper and validation', (
    tester,
  ) async {
    await _pump(tester, initial: '/admin/speaking/create');
    await tester.pumpAndSettle();
    expect(find.text('Identitas Template'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Publikasi'), findsOneWidget);
    expect(
      find.text('Terbitkan setelah judul dan kalimat latihan siap digunakan.'),
      findsOneWidget,
    );
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Simpan'),
    );
    save.onPressed!();
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, 700));
    await tester.pump();
    expect(find.text('Wajib diisi.'), findsNWidgets(2));
  });

  testWidgets('archive exact dialog copy and cancel keeps detail', (
    tester,
  ) async {
    await _pump(tester, initial: '/admin/speaking/s1');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Arsipkan'), 300);
    await tester.tap(find.text('Arsipkan'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Template akan disembunyikan dari latihan baru, tetapi data tetap tersimpan.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Template Speaking'), findsOneWidget);
  });

  testWidgets('AppBar back pops to speaking list', (tester) async {
    await _pump(tester, initial: '/admin/speaking');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salam'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminBackButton')));
    await tester.pumpAndSettle();
    expect(find.text('Cari judul atau kalimat latihan'), findsOneWidget);
  });

  testWidgets('large text scale has no overflow exception', (tester) async {
    await _pump(tester, initial: '/admin/speaking', textScale: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required String initial,
  List<RequestOptions>? requests,
  String status = 'published',
  int lastPage = 1,
  AdminSpeakingAudioPicker? picker,
  double textScale = 1,
}) async {
  final repository = _repository(
    requests: requests,
    status: status,
    lastPage: lastPage,
  );
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/admin/speaking',
        builder: (_, _) => const AdminSpeakingScreen(),
      ),
      GoRoute(
        path: '/admin/speaking/create',
        builder: (_, _) => const AdminSpeakingFormScreen(),
      ),
      GoRoute(
        path: '/admin/speaking/:id/edit',
        builder: (_, s) => AdminSpeakingFormScreen(id: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/speaking/:id',
        builder: (_, s) =>
            AdminSpeakingDetailScreen(id: s.pathParameters['id']!),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminSpeakingRepositoryProvider.overrideWithValue(repository),
        authControllerProvider.overrideWith((_) => _FakeAuthNotifier()),
        if (picker != null)
          adminSpeakingAudioPickerProvider.overrideWithValue(picker),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp.router(
          theme: EmiTheme.light(),
          routerConfig: router,
        ),
      ),
    ),
  );
}

AdminSpeakingRepository _repository({
  List<RequestOptions>? requests,
  bool publicAudio = true,
  bool error = false,
  String status = 'published',
  int lastPage = 1,
}) => AdminSpeakingRepository(
  Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests?.add(options);
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
          if (options.path.endsWith('/temporary-url')) {
            return handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': {'url': 'https://example.test/temporary.mp3'},
                },
              ),
            );
          }
          final item = _template(status: status, publicAudio: publicAudio);
          final data =
              options.path == '/admin/speaking/exercises' &&
                  options.method == 'GET'
              ? {
                  'data': [item],
                  'meta': {
                    'current_page': options.queryParameters['page'] ?? 1,
                    'last_page': lastPage,
                    'total': lastPage,
                  },
                }
              : {'data': item};
          handler.resolve(Response(requestOptions: options, data: data));
        },
      ),
    ),
  const DioErrorMapper(),
);

AdminSpeakingSaveRequest _request(
  String status, {
  String? audioId = 'old-media',
}) => AdminSpeakingSaveRequest(
  title: 'Salam',
  targetText: 'Mepokoaso',
  targetTranslation: 'Bersatu',
  promptText: 'Baca jelas',
  difficulty: 'beginner',
  status: status,
  referenceAudioMediaId: audioId,
);

Map<String, dynamic> _template({
  String status = 'published',
  bool publicAudio = true,
}) => {
  'id': 's1',
  'title': 'Salam',
  'target_text': 'Mepokoaso',
  'target_translation': 'Bersatu',
  'prompt_text': 'Baca jelas',
  'difficulty': 'beginner',
  'status': status,
  'updated_at': '2026-07-15T00:00:00Z',
  'reference_audio_media_id': 'old-media',
  'reference_audio': {
    'url': publicAudio ? 'https://example.test/audio.mp3' : null,
    'original_name': 'contoh.mp3',
  },
};

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthController {
  _FakeAuthNotifier()
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
