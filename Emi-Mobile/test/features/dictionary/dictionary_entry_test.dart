import 'dart:async';

import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/core/network/network_status_controller.dart';
import 'package:emi_mobile/features/dictionary/data/dictionary_entry.dart';
import 'package:emi_mobile/features/dictionary/data/dictionary_providers.dart';
import 'package:emi_mobile/features/dictionary/presentation/dictionary_list_screen.dart';
import 'package:emi_mobile/features/dictionary/presentation/dictionary_offline_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

class _AuthRepository extends Mock implements AuthRepository {}

class _AudioPlayer implements DictionaryAudioPlayer {
  final states = StreamController<PlayerState>.broadcast();
  final setUrlGate = Completer<void>();
  int setUrlCalls = 0;
  int playCalls = 0;
  String? source;
  bool disposed = false;
  bool fail = false;

  @override
  bool get hasSource => false;
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Future<void> setUrl(String url) async {
    source = url;
    setUrlCalls++;
    if (fail) throw StateError('audio');
    await setUrlGate.future;
  }

  @override
  Future<void> play() async => playCalls++;
  @override
  Future<void> pause() async {}
  @override
  Future<void> dispose() async {
    disposed = true;
    await states.close();
  }
}

void main() {
  testWidgets('audio stays on list, loads once, errors friendly, disposes', (
    tester,
  ) async {
    final audio = _AudioPlayer();
    final router = await _pumpDictionary(tester, audio: audio);
    final button = find.byKey(const Key('dictionaryAudio-entry-1'));
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/student/dictionary',
    );
    expect(audio.setUrlCalls, 1);
    audio.setUrlGate.complete();
    await tester.pump();
    expect(audio.playCalls, 1);
    await tester.pumpWidget(const SizedBox());
    expect(audio.disposed, true);

    final failed = _AudioPlayer()..fail = true;
    await _pumpDictionary(tester, audio: failed);
    await tester.tap(find.byKey(const Key('dictionaryAudio-entry-1')));
    await tester.pump();
    expect(find.text('Audio gagal diputar. Coba lagi.'), findsOneWidget);
  });

  testWidgets('list audio uses local source and explains missing download', (
    tester,
  ) async {
    final audio = _AudioPlayer();
    await _pumpDictionary(
      tester,
      audio: audio,
      audioSource: 'file:///offline/entry.mp3',
    );
    await tester.tap(find.byKey(const Key('dictionaryAudio-entry-1')));
    audio.setUrlGate.complete();
    await tester.pump();
    expect(audio.source, 'file:///offline/entry.mp3');

    await tester.pumpWidget(const SizedBox());
    await _pumpDictionary(tester, audio: _AudioPlayer(), audioSource: null);
    expect(find.byKey(const Key('dictionaryAudio-entry-1')), findsNothing);
    expect(
      find.text('Audio belum diunduh untuk penggunaan offline.'),
      findsOneWidget,
    );
  });

  testWidgets('absent audio hidden', (tester) async {
    await _pumpDictionary(tester, audio: _AudioPlayer(), audioAvailable: false);
    expect(find.byKey(const Key('dictionaryAudio-entry-1')), findsNothing);
  });

  testWidgets('package badges and download dialog show audio option', (
    tester,
  ) async {
    await _pumpDictionary(
      tester,
      audio: _AudioPlayer(),
      packageState: const DictionaryPackageState(
        DictionaryPackageStatus.updateAvailable,
        isNew: true,
      ),
    );
    expect(find.text('BARU'), findsOneWidget);
    expect(find.text('Pembaruan'), findsOneWidget);
    expect(find.text('Update Available'), findsOneWidget);
    await tester.tap(find.text('Update Available'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Kata dan arti wajib diunduh agar kategori dapat dicari tanpa internet.',
      ),
      findsOneWidget,
    );
    expect(find.text('Contoh kalimat ikut diunduh.'), findsOneWidget);
    expect(find.text('Sertakan audio'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      true,
    );
    await tester.tap(find.text('Batal'));
  });

  testWidgets('offline empty search uses saved dictionary wording', (
    tester,
  ) async {
    await _pumpDictionary(
      tester,
      audio: _AudioPlayer(),
      empty: true,
      offline: true,
    );
    expect(
      find.text('Kata tidak ditemukan di kamus yang tersimpan.'),
      findsOneWidget,
    );
  });

  testWidgets('pagination boundaries and search reset page', (tester) async {
    final queries = <DictionaryQuery>[];
    await _pumpDictionary(tester, audio: _AudioPlayer(), queries: queries);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('dictionaryPreviousPage')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('dictionaryNextPage')));
    await tester.pumpAndSettle();
    expect(queries.last.page, 2);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('dictionaryNextPage')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Inggris'));
    await tester.pumpAndSettle();
    expect(queries.last.page, 1);
    expect(queries.last.language, 'english');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Kategori'));
    await tester.pumpAndSettle();
    expect(queries.last.page, 1);
    expect(queries.last.categoryId, 'category-1');
    await tester.tap(find.byKey(const Key('dictionaryNextPage')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'monga');
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pumpAndSettle();
    expect(queries.last.page, 1);
    expect(queries.last.search, 'monga');
  });

  test('maps dictionary page json', () {
    final page = DictionaryPage.fromJson({
      'data': [
        {
          'id': 'entry-1',
          'category': {
            'id': 'cat-1',
            'name': 'Kata Kerja',
            'slug': 'kata-kerja',
          },
          'category_id': 'cat-1',
          'indonesia': 'makan',
          'english': 'eat',
          'mekongga': 'monga',
          'status': 'active',
          'audio': {
            'id': 'media-1',
            'url': 'https://example.test/audio.mp3',
            'mime_type': 'audio/mpeg',
          },
        },
      ],
      'meta': {'current_page': 1, 'last_page': 2, 'total': 1},
    });

    expect(page.items.single.mekongga, 'monga');
    expect(page.items.single.category?.name, 'Kata Kerja');
    expect(page.items.single.hasAudio, true);
    expect(page.hasNextPage, true);
  });

  test('maps dictionary sentence examples json', () {
    final entry = DictionaryEntry.fromJson({
      'id': 'entry-1',
      'indonesia': 'makan',
      'english': 'eat',
      'mekongga': 'monga',
      'example_mekongga': 'Monga ine momi.',
      'example_indonesia': 'Dia sedang makan nasi.',
      'sentence_examples': [
        {
          'id': 'example-1',
          'kode': 'EX-1',
          'contoh_mekongga': 'Ono monga ikan.',
          'contoh_indonesia': 'Anak itu makan ikan.',
        },
      ],
      'status': 'active',
    });

    expect(entry.exampleMekongga, 'Monga ine momi.');
    expect(entry.examples.single.mekongga, 'Ono monga ikan.');
  });

  test('handles null audio', () {
    final entry = DictionaryEntry.fromJson({
      'id': 'entry-1',
      'indonesia': 'rumah',
      'english': 'house',
      'mekongga': 'laika',
      'audio': null,
      'status': 'active',
    });

    expect(entry.hasAudio, false);
  });
}

Future<GoRouter> _pumpDictionary(
  WidgetTester tester, {
  required _AudioPlayer audio,
  bool audioAvailable = true,
  List<DictionaryQuery>? queries,
  String? audioSource = 'https://example.test/audio.mp3',
  DictionaryPackageState packageState = const DictionaryPackageState(
    DictionaryPackageStatus.download,
  ),
  bool empty = false,
  bool offline = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/student/dictionary',
    routes: [
      GoRoute(
        path: '/student/dictionary',
        builder: (_, _) => const DictionaryListScreen(),
      ),
      GoRoute(
        path: '/student/dictionary/:id',
        builder: (_, _) => const Text('DETAIL'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthRepository()),
        dictionaryAudioPlayerFactoryProvider.overrideWithValue(() => audio),
        dictionaryAudioSourceProvider.overrideWith(
          (_, query) async => audioSource,
        ),
        dictionaryNetworkModeProvider.overrideWithValue(
          offline ? NetworkMode.offline : NetworkMode.online,
        ),
        dictionaryPackageStateProvider(
          'category-1',
        ).overrideWith((_) => Stream.value(packageState)),
        dictionaryCategorySourceProvider.overrideWith(
          (_) async => DictionaryPage(
            items: [_entry(audioAvailable: audioAvailable)],
            currentPage: 1,
            lastPage: 1,
            total: 1,
          ),
        ),
        dictionaryListProvider.overrideWith((_, query) async {
          queries?.add(query);
          return DictionaryPage(
            items: empty ? const [] : [_entry(audioAvailable: audioAvailable)],
            currentPage: query.page,
            lastPage: 2,
            total: empty ? 0 : 2,
          );
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

DictionaryEntry _entry({required bool audioAvailable}) => DictionaryEntry(
  id: 'entry-1',
  indonesia: 'makan',
  english: 'eat',
  mekongga: 'monga',
  status: 'active',
  examples: const [],
  category: const DictionaryCategory(id: 'category-1', name: 'Kategori'),
  categoryId: 'category-1',
  audio: audioAvailable
      ? const DictionaryAudio(
          id: 'audio-1',
          url: 'https://example.test/audio.mp3',
        )
      : null,
);
