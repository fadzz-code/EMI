import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/core/offline/offline_database.dart';
import 'package:emi_mobile/core/offline/offline_file_store.dart';
import 'package:emi_mobile/features/dictionary/data/dictionary_repository.dart';
import 'package:emi_mobile/features/dictionary/data/offline_dictionary_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory directory;
  late OfflineDatabase database;
  late OfflineFileStore files;
  late _Api api;
  late OfflineDictionaryRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('emi-dictionary-');
    database = await OfflineDatabase.open(
      path: '${directory.path}${Platform.pathSeparator}db.sqlite',
    );
    files = await OfflineFileStore.open(supportDirectory: directory);
    api = _Api();
    final dio = Dio()..httpClientAdapter = api;
    repository = OfflineDictionaryRepository(
      database: database,
      fileStore: files,
      dio: dio,
      remote: DictionaryRepository(dio, const DioErrorMapper()),
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('normalizes trim NFC case and collapsed whitespace', () {
    expect(normalizeDictionaryText('  A  B\nC  '), 'a b c');
    expect(normalizeDictionaryText('Cafe\u0301'), 'café');
  });

  test('downloads paged UUID-deduped details, sentences, and audio', () async {
    final package = await repository.download('owner-a', 'cat');
    expect(package.entryCount, 2);
    expect(api.listPages, [1, 2]);
    expect(api.details, ['one', 'poly']);
    expect(
      await database.readAll(
        ownerStudentId: 'owner-a',
        table: 'offline_dictionary_entries',
      ),
      hasLength(2),
    );
    expect(
      await database.readAll(
        ownerStudentId: 'owner-a',
        table: 'offline_dictionary_sentences',
      ),
      hasLength(1),
    );
    expect(await files.exists('owner-a', api.audioRef), isTrue);
  });

  test(
    'local literal language/category search has stable pagination',
    () async {
      await repository.download('owner-a', 'cat', includeAudio: false);
      final first = await repository.localList(
        'owner-a',
        search: ' MAK ',
        language: 'indonesia',
        categoryId: 'cat',
        perPage: 1,
      );
      expect(first.total, 2);
      expect(first.items.single.id, 'one');
      final second = await repository.localList(
        'owner-a',
        search: 'mak',
        language: 'indonesia',
        categoryId: 'cat',
        page: 2,
        perPage: 1,
      );
      expect(second.items.single.id, 'poly');
      expect(
        (await repository.localDetail('owner-a', 'one'))!.examples,
        hasLength(1),
      );
      expect(await repository.localList('owner-b'), isA<dynamic>());
      expect((await repository.localList('owner-b')).items, isEmpty);
    },
  );

  test('seen and update state remain owner scoped', () async {
    expect(await repository.markManifestSeen('owner-a', ['cat']), {'cat'});
    expect(await repository.markManifestSeen('owner-a', ['cat']), isEmpty);
    expect(await repository.seenManifestCategories('owner-b'), isEmpty);
    await repository.download('owner-a', 'cat', includeAudio: false);
    api.version = 'v2';
    expect(await repository.updateAvailable('owner-a'), {'cat'});
    expect(await repository.updateAvailable('owner-b'), isEmpty);
  });

  test('failed integrity and changed manifest preserve old package', () async {
    await repository.download('owner-a', 'cat', includeAudio: false);
    api
      ..version = 'v2'
      ..badAudio = true;
    await expectLater(repository.download('owner-a', 'cat'), throwsStateError);
    final row = (await database.readAll(
      ownerStudentId: 'owner-a',
      table: 'offline_packages',
    )).single;
    expect((jsonDecode(row['data_json'] as String) as Map)['version'], 'v1');
  });

  test(
    'remote-first falls back on transport but propagates semantic errors',
    () async {
      await repository.download('owner-a', 'cat', includeAudio: false);
      api.listError = 503;
      expect((await repository.list('owner-a')).total, 2);
      api.listError = 422;
      await expectLater(
        repository.list('owner-a'),
        throwsA(
          isA<AppError>().having(
            (value) => value.type,
            'type',
            AppErrorType.validation,
          ),
        ),
      );
    },
  );

  test(
    'manifest reconciliation retires absent package and preserves shared media',
    () async {
      await repository.download('owner-a', 'cat');
      await database.put(
        ownerStudentId: 'owner-a',
        table: 'offline_media',
        id: 'other',
        data: {'dictionary_category_id': 'other', 'file_ref': api.audioRef},
      );
      api.manifestIds = const [];
      expect(
        await repository.reconcileManifest(
          'owner-a',
          await repository.manifest(),
        ),
        {'cat'},
      );
      expect(await repository.installedCategories('owner-a'), isEmpty);
      expect(await files.exists('owner-a', api.audioRef), isTrue);
    },
  );

  test('audio mode persists and explicit audio removal updates mode', () async {
    await repository.download('owner-a', 'cat');
    expect(await repository.packageIncludesAudio('owner-a', 'cat'), isTrue);
    await repository.download('owner-a', 'cat', includeAudio: false);
    expect(await repository.packageIncludesAudio('owner-a', 'cat'), isFalse);
    expect(await files.exists('owner-a', api.audioRef), isFalse);
  });

  test('remove clears package and unshared files only', () async {
    await repository.download('owner-a', 'cat');
    await database.put(
      ownerStudentId: 'owner-a',
      table: 'offline_media',
      id: 'other',
      data: {'dictionary_category_id': 'other', 'file_ref': api.audioRef},
    );
    await repository.remove('owner-a', 'cat');
    expect(await repository.localDetail('owner-a', 'one'), isNull);
    expect(await files.exists('owner-a', api.audioRef), isTrue);
  });
}

class _Api implements HttpClientAdapter {
  final bytes = utf8.encode('audio');
  String version = 'v1';
  bool badAudio = false;
  int? listError;
  List<String> manifestIds = const ['cat'];
  final listPages = <int>[];
  final details = <String>[];

  String get checksum => sha256.convert(bytes).toString();
  String get audioRef => 'audio@$checksum';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/student/offline/manifest') {
      return _json({
        'data': {
          'schema_version': 1,
          'dictionaries': manifestIds
              .map((id) => {'id': id, 'version': version})
              .toList(),
        },
      });
    }
    if (options.path == '/dictionary') {
      if (listError != null) {
        return _json({'message': 'failed'}, statusCode: listError!);
      }
      final page = options.queryParameters['page'] as int;
      listPages.add(page);
      return _json({
        'data': page == 1
            ? [_summary('one'), _summary('one')]
            : [_summary('poly')],
        'meta': {'current_page': page, 'last_page': 2, 'total': 3},
      });
    }
    if (options.path.startsWith('/dictionary/')) {
      final id = options.path.split('/').last;
      details.add(id);
      return _json({'data': _detail(id)});
    }
    if (options.path == 'https://example.test/audio') {
      final body = badAudio ? [0] : bytes;
      return ResponseBody.fromBytes(body, 200);
    }
    return ResponseBody.fromString('', 404);
  }

  Map<String, Object?> _summary(String id) => {
    'id': id,
    'category_id': 'cat',
    'indonesia': id == 'one' ? 'makan' : 'makanan',
    'mekongga': id == 'one' ? 'monga' : 'monga dua',
    'english': id == 'one' ? 'eat' : 'food',
    'status': 'active',
  };

  Map<String, Object?> _detail(String id) => {
    ..._summary(id),
    'sentence_examples': id == 'one'
        ? [
            {
              'id': 'sentence',
              'contoh_mekongga': 'Monga.',
              'contoh_indonesia': 'Makan.',
              'status': 'active',
              'audio': _audio(),
            },
            {'id': 'inactive', 'status': 'inactive'},
          ]
        : [],
    if (id == 'one') 'audio': _audio(),
  };

  Map<String, Object?> _audio() => {
    'id': 'audio',
    'url': 'https://example.test/audio',
    'mime_type': 'audio/mpeg',
    'size_bytes': bytes.length,
    'checksum_sha256': checksum,
  };

  ResponseBody _json(Map<String, Object?> value, {int statusCode = 200}) =>
      ResponseBody.fromString(
        jsonEncode(value),
        statusCode,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );

  @override
  void close({bool force = false}) {}
}
