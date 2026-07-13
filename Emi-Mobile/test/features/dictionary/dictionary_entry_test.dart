import 'package:emi_mobile/features/dictionary/data/dictionary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
