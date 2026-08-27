import 'dart:async';

import 'package:emi_mobile/features/dictionary/data/dictionary_entry.dart';
import 'package:emi_mobile/features/dictionary/data/dictionary_providers.dart';
import 'package:emi_mobile/features/dictionary/presentation/dictionary_detail_screen.dart';
import 'package:emi_mobile/features/dictionary/presentation/dictionary_offline_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';

class _Player implements DictionaryAudioPlayer {
  final states = StreamController<PlayerState>.broadcast();
  String? source;

  @override
  bool get hasSource => source != null;
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Future<void> setUrl(String url) async => source = url;
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> dispose() => states.close();
}

void main() {
  testWidgets('local detail uses local entry and sentence audio sources', (
    tester,
  ) async {
    final players = <_Player>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          integratedDictionaryDetailProvider(
            'entry-1',
          ).overrideWith((_) async => _entry),
          dictionaryAudioSourceProvider.overrideWith(
            (_, query) async => 'file:///offline/${query.id}.mp3',
          ),
          dictionaryAudioPlayerFactoryProvider.overrideWithValue(() {
            final player = _Player();
            players.add(player);
            return player;
          }),
        ],
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Putar audio').first);
    await tester.ensureVisible(
      find.byKey(const Key('dictionarySentenceAudio-sentence-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Putar audio').last);
    await tester.pump();
    expect(
      players.map((player) => player.source),
      containsAll([
        'file:///offline/entry-audio.mp3',
        'file:///offline/sentence-audio.mp3',
      ]),
    );
  });

  testWidgets('local detail explains audio not downloaded', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          integratedDictionaryDetailProvider(
            'entry-1',
          ).overrideWith((_) async => _entry),
          dictionaryAudioSourceProvider.overrideWith((_, query) async => null),
          dictionaryAudioPlayerFactoryProvider.overrideWithValue(_Player.new),
        ],
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Audio belum diunduh untuk penggunaan offline.'),
      findsNWidgets(2),
    );
    expect(find.byTooltip('Putar audio'), findsNothing);
  });
}

GoRouter _router() => GoRouter(
  initialLocation: '/student/dictionary/entry-1',
  routes: [
    GoRoute(
      path: '/student/dictionary/:id',
      builder: (_, state) =>
          DictionaryDetailScreen(entryId: state.pathParameters['id']!),
    ),
  ],
);

const _entry = DictionaryEntry(
  id: 'entry-1',
  indonesia: 'makan',
  english: 'eat',
  mekongga: 'monga',
  status: 'active',
  audio: DictionaryAudio(id: 'entry-audio', url: 'https://remote/entry.mp3'),
  examples: [
    DictionaryExample(
      id: 'sentence-1',
      mekongga: 'Monga.',
      indonesia: 'Makan.',
      audio: DictionaryAudio(
        id: 'sentence-audio',
        url: 'https://remote/sentence.mp3',
      ),
    ),
  ],
);
