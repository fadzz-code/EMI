import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'dictionary_entry.dart';
import 'dictionary_repository.dart';

abstract interface class DictionaryAudioPlayer {
  Stream<PlayerState> get playerStateStream;
  bool get hasSource;
  Future<void> setUrl(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

class JustAudioDictionaryPlayer implements DictionaryAudioPlayer {
  JustAudioDictionaryPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  bool get hasSource => _player.audioSource != null;

  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  Future<void> setUrl(String url) => _player.setUrl(url);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> dispose() => _player.dispose();
}

final dictionaryAudioPlayerFactoryProvider =
    Provider<DictionaryAudioPlayer Function()>(
      (_) => JustAudioDictionaryPlayer.new,
    );

final dictionaryRepositoryProvider = Provider<DictionaryRepository>(
  (ref) => DictionaryRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

class DictionaryQuery {
  const DictionaryQuery({this.search, this.categoryId, this.page = 1});

  final String? search;
  final String? categoryId;
  final int page;

  @override
  bool operator ==(Object other) {
    return other is DictionaryQuery &&
        other.search == search &&
        other.categoryId == categoryId &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(search, categoryId, page);
}

final dictionaryListProvider = FutureProvider.autoDispose
    .family<DictionaryPage, DictionaryQuery>(
      (ref, query) => ref
          .watch(dictionaryRepositoryProvider)
          .list(
            search: query.search,
            categoryId: query.categoryId,
            page: query.page,
          ),
    );

final dictionaryDetailProvider = FutureProvider.autoDispose
    .family<DictionaryEntry, String>(
      (ref, id) => ref.watch(dictionaryRepositoryProvider).detail(id),
    );
