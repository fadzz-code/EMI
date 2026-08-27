import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/offline/offline_database.dart';
import '../../../core/offline/offline_file_store.dart';
import 'dictionary_entry.dart';
import 'dictionary_repository.dart';

class DictionaryManifestItem {
  const DictionaryManifestItem({
    required this.categoryId,
    required this.version,
  });
  final String categoryId;
  final String version;
}

class OfflineDictionaryPackage {
  const OfflineDictionaryPackage({
    required this.categoryId,
    required this.version,
    required this.downloadedAt,
    required this.entryCount,
  });
  final String categoryId;
  final String version;
  final DateTime downloadedAt;
  final int entryCount;
}

class OfflineDictionaryRepository {
  const OfflineDictionaryRepository({
    required OfflineDatabase database,
    required OfflineFileStore fileStore,
    required Dio dio,
    required DictionaryRepository remote,
  }) : _database = database,
       _files = fileStore,
       _dio = dio,
       _remote = remote;

  final OfflineDatabase _database;
  final OfflineFileStore _files;
  final Dio _dio;
  final DictionaryRepository _remote;

  Future<List<DictionaryManifestItem>> manifest() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/student/offline/manifest',
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic> ||
        data['schema_version'] != 1 ||
        data['dictionaries'] is! List) {
      throw StateError('Manifest offline tidak valid.');
    }
    return (data['dictionaries'] as List)
        .whereType<Map<String, dynamic>>()
        .map(
          (value) => DictionaryManifestItem(
            categoryId: value['id'] as String,
            version: value['version'] as String,
          ),
        )
        .toList();
  }

  Future<OfflineDictionaryPackage> download(
    String owner,
    String categoryId, {
    bool includeAudio = true,
  }) async {
    _validate(owner, 'ownerStudentId');
    _validate(categoryId, 'categoryId');
    final version = _version(await manifest(), categoryId);
    if (version == null) {
      throw StateError('Kategori tidak tersedia untuk offline.');
    }
    final summaries = <String, DictionaryEntry>{};
    var page = 1;
    while (true) {
      final value = await _remote.list(
        categoryId: categoryId,
        page: page,
        perPage: 100,
      );
      for (final entry in value.items) {
        if (entry.id.isNotEmpty) summaries.putIfAbsent(entry.id, () => entry);
      }
      if (!value.hasNextPage) break;
      page++;
    }
    if (summaries.isEmpty) {
      throw StateError('Kategori tidak memiliki entri aktif.');
    }
    final entries = <DictionaryEntry>[];
    for (final id in summaries.keys) {
      final detail = await _remote.detail(id);
      if (detail.status == 'active' && detail.categoryId == categoryId) {
        entries.add(detail);
      }
    }
    final media = <String, DictionaryAudio>{};
    if (includeAudio) {
      for (final entry in entries) {
        if (entry.audio != null) media[entry.audio!.id] = entry.audio!;
        for (final sentence in entry.examples.where(
          (value) => value.status == 'active',
        )) {
          if (sentence.audio != null) {
            media[sentence.audio!.id] = sentence.audio!;
          }
        }
      }
    }
    final stagedRefs = <String>{};
    try {
      for (final audio in media.values) {
        if (!audio.hasIntegrity || audio.url.isEmpty) {
          throw StateError('Metadata audio ${audio.id} tidak lengkap.');
        }
        final ref = _files.immutableRef(audio.id, audio.checksumSha256!);
        final file = File(_files.pathFor(owner, ref));
        if (!await _valid(file, audio)) {
          final response = await _dio.get<List<int>>(
            audio.url,
            options: Options(responseType: ResponseType.bytes),
          );
          final bytes = response.data;
          if (bytes == null || !_validBytes(bytes, audio)) {
            throw StateError('Integritas audio ${audio.id} tidak valid.');
          }
          await _files.write(owner, ref, bytes);
          stagedRefs.add(ref);
        }
      }
      if (_version(await manifest(), categoryId) != version) {
        throw StateError('Kategori berubah saat diunduh. Silakan coba lagi.');
      }
      final oldRefs = await _refs(owner, categoryId);
      final now = DateTime.now().toUtc();
      await _database.database.transaction((txn) async {
        await _deleteRows(txn, owner, categoryId);
        for (final entry in entries) {
          await txn.insert('offline_dictionary_entries', {
            'owner_student_id': owner,
            'id': entry.id,
            'data_json': jsonEncode(_entryJson(entry)),
            'category_id': categoryId,
            'indonesia_normalized': normalizeDictionaryText(entry.indonesia),
            'mekongga_normalized': normalizeDictionaryText(entry.mekongga),
            'english_normalized': normalizeDictionaryText(entry.english),
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          for (final sentence in entry.examples.where(
            (value) => value.status == 'active',
          )) {
            await _put(
              txn,
              'offline_dictionary_sentences',
              owner,
              sentence.id,
              {
                'category_id': categoryId,
                'entry_id': entry.id,
                'sentence': _exampleJson(sentence),
              },
              now,
            );
          }
        }
        for (final audio in media.values) {
          final ref = _files.immutableRef(audio.id, audio.checksumSha256!);
          await _put(
            txn,
            'offline_media',
            owner,
            'dictionary:$categoryId:$ref',
            {
              'dictionary_category_id': categoryId,
              'file_ref': ref,
              'media': _audioJson(audio),
            },
            now,
          );
        }
        await _put(txn, 'offline_packages', owner, categoryId, {
          'kind': 'dictionary',
          'version': version,
          'downloaded_at': now.toIso8601String(),
          'include_audio': includeAudio,
        }, now);
      });
      for (final ref in oldRefs.difference(
        media.values
            .map(
              (audio) => _files.immutableRef(audio.id, audio.checksumSha256!),
            )
            .toSet(),
      )) {
        if (!await _refUsed(owner, ref)) await _files.delete(owner, ref);
      }
      return OfflineDictionaryPackage(
        categoryId: categoryId,
        version: version,
        downloadedAt: now,
        entryCount: entries.length,
      );
    } catch (_) {
      for (final ref in stagedRefs) {
        if (!await _refUsed(owner, ref)) await _files.delete(owner, ref);
      }
      rethrow;
    }
  }

  Future<DictionaryPage> localList(
    String owner, {
    String? search,
    String language = 'all',
    String? categoryId,
    int page = 1,
    int perPage = 15,
  }) async {
    _validate(owner, 'ownerStudentId');
    if (page < 1 || perPage < 1) throw ArgumentError('Pagination tidak valid.');
    const columns = {'indonesia', 'mekongga', 'english'};
    if (language != 'all' && !columns.contains(language)) {
      throw ArgumentError.value(language, 'language');
    }
    final where = <String>['owner_student_id = ?'];
    final args = <Object?>[owner];
    if (categoryId?.isNotEmpty == true) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    final query = normalizeDictionaryText(search ?? '');
    if (query.isNotEmpty) {
      final selected = language == 'all' ? columns : {language};
      where.add(
        '(${selected.map((value) => 'instr(${value}_normalized, ?) > 0').join(' OR ')})',
      );
      args.addAll(List.filled(selected.length, query));
    }
    final condition = where.join(' AND ');
    final count =
        Sqflite.firstIntValue(
          await _database.database.rawQuery(
            'SELECT COUNT(*) FROM offline_dictionary_entries WHERE $condition',
            args,
          ),
        ) ??
        0;
    final rows = await _database.database.query(
      'offline_dictionary_entries',
      where: condition,
      whereArgs: args,
      orderBy: 'indonesia_normalized, id',
      limit: perPage,
      offset: (page - 1) * perPage,
    );
    return DictionaryPage(
      items: rows.map((row) => DictionaryEntry.fromJson(_decode(row))).toList(),
      currentPage: page,
      lastPage: count == 0 ? 1 : (count / perPage).ceil(),
      total: count,
    );
  }

  Future<DictionaryEntry?> localDetail(String owner, String id) async {
    _validate(owner, 'ownerStudentId');
    final rows = await _database.database.query(
      'offline_dictionary_entries',
      where: 'owner_student_id = ? AND id = ?',
      whereArgs: [owner, id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final json = _decode(rows.single);
    final sentences = await _database.database.query(
      'offline_dictionary_sentences',
      where: 'owner_student_id = ?',
      whereArgs: [owner],
    );
    json['sentence_examples'] = sentences
        .map(_decode)
        .where((value) => value['entry_id'] == id)
        .map((value) => value['sentence'])
        .toList();
    return DictionaryEntry.fromJson(json);
  }

  Future<DictionaryPage> list(
    String owner, {
    String? search,
    String language = 'all',
    String? categoryId,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      return await _remote.list(
        search: search,
        language: language,
        categoryId: categoryId,
        page: page,
        perPage: perPage,
      );
    } on AppError catch (error) {
      if (!_transport(error)) rethrow;
      return localList(
        owner,
        search: search,
        language: language,
        categoryId: categoryId,
        page: page,
        perPage: perPage,
      );
    }
  }

  Future<DictionaryEntry> detail(String owner, String id) async {
    try {
      return await _remote.detail(id);
    } on AppError catch (error) {
      if (!_transport(error)) rethrow;
      final local = await localDetail(owner, id);
      if (local == null) rethrow;
      return local;
    }
  }

  Future<Set<String>> markManifestSeen(
    String owner,
    Iterable<String> categoryIds,
  ) async {
    _validate(owner, 'ownerStudentId');
    final existing = await seenManifestCategories(owner);
    final ids = categoryIds.where((value) => value.isNotEmpty).toSet();
    final fresh = ids.difference(existing);
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.database.transaction((txn) async {
      for (final id in ids) {
        await txn.insert(
          'offline_dictionary_seen_categories',
          {'owner_student_id': owner, 'category_id': id, 'created_at': now},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
    return fresh;
  }

  Future<Set<String>> seenManifestCategories(String owner) async =>
      (await _database.database.query(
        'offline_dictionary_seen_categories',
        columns: ['category_id'],
        where: 'owner_student_id = ?',
        whereArgs: [owner],
      )).map((row) => row['category_id'] as String).toSet();

  Future<Set<String>> installedCategories(String owner) async {
    _validate(owner, 'ownerStudentId');
    final rows = await _database.database.query(
      'offline_packages',
      where: 'owner_student_id = ?',
      whereArgs: [owner],
    );
    return rows
        .where((row) => _decode(row)['kind'] == 'dictionary')
        .map((row) => row['id'] as String)
        .toSet();
  }

  Future<String?> localAudioUrl(String owner, String audioId) async {
    _validate(owner, 'ownerStudentId');
    final rows = await _database.database.query(
      'offline_media',
      where: 'owner_student_id = ?',
      whereArgs: [owner],
    );
    for (final row in rows) {
      final data = _decode(row);
      final media = data['media'];
      if (media is Map<String, dynamic> && media['id'] == audioId) {
        final ref = data['file_ref'] as String;
        if (await _files.exists(owner, ref)) {
          return File(_files.pathFor(owner, ref)).uri.toString();
        }
      }
    }
    return null;
  }

  Future<bool> packageIncludesAudio(String owner, String categoryId) async {
    final rows = await _database.database.query(
      'offline_packages',
      where: 'owner_student_id = ? AND id = ?',
      whereArgs: [owner, categoryId],
      limit: 1,
    );
    return rows.isNotEmpty && _decode(rows.single)['include_audio'] == true;
  }

  Future<Set<String>> reconcileManifest(
    String owner,
    List<DictionaryManifestItem> manifest,
  ) async {
    final remoteIds = manifest.map((value) => value.categoryId).toSet();
    final retired = (await installedCategories(owner)).difference(remoteIds);
    final refs = <String>{};
    await _database.database.transaction((txn) async {
      for (final categoryId in retired) {
        refs.addAll(await _refsFrom(txn, owner, categoryId));
        await _deleteRows(txn, owner, categoryId);
      }
    });
    for (final ref in refs) {
      if (!await _refUsed(owner, ref)) await _files.delete(owner, ref);
    }
    return retired;
  }

  Future<Set<String>> updateAvailable(
    String owner, {
    List<DictionaryManifestItem>? authoritativeManifest,
  }) async {
    final remote = {
      for (final value in authoritativeManifest ?? await manifest())
        value.categoryId: value.version,
    };
    final rows = await _database.database.query(
      'offline_packages',
      where: 'owner_student_id = ?',
      whereArgs: [owner],
    );
    return rows
        .where((row) => _decode(row)['kind'] == 'dictionary')
        .where(
          (row) =>
              remote[row['id']] != null &&
              remote[row['id']] != _decode(row)['version'],
        )
        .map((row) => row['id'] as String)
        .toSet();
  }

  Future<void> remove(String owner, String categoryId) async {
    final refs = await _refs(owner, categoryId);
    await _database.database.transaction(
      (txn) => _deleteRows(txn, owner, categoryId),
    );
    for (final ref in refs) {
      if (!await _refUsed(owner, ref)) await _files.delete(owner, ref);
    }
  }

  static String? _version(List<DictionaryManifestItem> values, String id) =>
      values
          .where((value) => value.categoryId == id)
          .map((value) => value.version)
          .firstOrNull;
  static bool _transport(AppError error) =>
      error.type == AppErrorType.networkUnavailable ||
      error.type == AppErrorType.timeout ||
      error.type == AppErrorType.server;
  static bool _validBytes(List<int> bytes, DictionaryAudio audio) =>
      bytes.length == audio.sizeBytes &&
      sha256.convert(bytes).toString() == audio.checksumSha256!.toLowerCase();
  static Future<bool> _valid(File file, DictionaryAudio audio) async =>
      await file.exists() && _validBytes(await file.readAsBytes(), audio);
  static Map<String, dynamic> _decode(Map<String, Object?> row) =>
      jsonDecode(row['data_json'] as String) as Map<String, dynamic>;

  Future<Set<String>> _refs(String owner, String categoryId) =>
      _refsFrom(_database.database, owner, categoryId);
  static Future<Set<String>> _refsFrom(
    DatabaseExecutor database,
    String owner,
    String categoryId,
  ) async =>
      (await database.query(
            'offline_media',
            where: 'owner_student_id = ?',
            whereArgs: [owner],
          ))
          .map(_decode)
          .where((value) => value['dictionary_category_id'] == categoryId)
          .map((value) => value['file_ref'] as String)
          .toSet();
  Future<bool> _refUsed(String owner, String ref) async =>
      (await _database.database.query(
        'offline_media',
        where: 'owner_student_id = ?',
        whereArgs: [owner],
      )).any((row) => _decode(row)['file_ref'] == ref);

  static Future<void> _deleteRows(
    Transaction txn,
    String owner,
    String categoryId,
  ) async {
    for (final table in ['offline_packages', 'offline_dictionary_entries']) {
      await txn.delete(
        table,
        where:
            'owner_student_id = ? AND ${table == 'offline_packages' ? 'id' : 'category_id'} = ?',
        whereArgs: [owner, categoryId],
      );
    }
    for (final table in ['offline_dictionary_sentences', 'offline_media']) {
      final key = table == 'offline_media'
          ? 'dictionary_category_id'
          : 'category_id';
      final rows = await txn.query(
        table,
        where: 'owner_student_id = ?',
        whereArgs: [owner],
      );
      for (final row in rows.where((row) => _decode(row)[key] == categoryId)) {
        await txn.delete(
          table,
          where: 'owner_student_id = ? AND id = ?',
          whereArgs: [owner, row['id']],
        );
      }
    }
  }

  static Future<void> _put(
    Transaction txn,
    String table,
    String owner,
    String id,
    Map<String, Object?> data,
    DateTime now,
  ) => txn.insert(table, {
    'owner_student_id': owner,
    'id': id,
    'data_json': jsonEncode(data),
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  });
  static void _validate(String value, String name) {
    if (value.trim().isEmpty) throw ArgumentError.value(value, name);
  }
}

String normalizeDictionaryText(String value) =>
    _nfc(value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '));

String _nfc(String value) {
  const marks = {
    '\u0300': 'àèìòùÀÈÌÒÙ',
    '\u0301': 'áéíóúýÁÉÍÓÚÝ',
    '\u0302': 'âêîôûÂÊÎÔÛ',
    '\u0303': 'ãñõÃÑÕ',
    '\u0308': 'äëïöüÿÄËÏÖÜŸ',
    '\u0327': 'çÇ',
  };
  const bases = {
    '\u0300': 'aeiouAEIOU',
    '\u0301': 'aeiouyAEIOUY',
    '\u0302': 'aeiouAEIOU',
    '\u0303': 'anoANO',
    '\u0308': 'aeiouyAEIOUY',
    '\u0327': 'cC',
  };
  var result = value;
  for (final mark in marks.keys) {
    for (var index = 0; index < bases[mark]!.length; index++) {
      result = result.replaceAll(
        '${bases[mark]![index]}$mark',
        marks[mark]![index],
      );
    }
  }
  return result;
}

Map<String, Object?> _entryJson(DictionaryEntry value) => {
  'id': value.id,
  'category_id': value.categoryId,
  if (value.category != null)
    'category': {
      'id': value.category!.id,
      'name': value.category!.name,
      'slug': value.category!.slug,
    },
  'indonesia': value.indonesia,
  'mekongga': value.mekongga,
  'english': value.english,
  'example_mekongga': value.exampleMekongga,
  'example_indonesia': value.exampleIndonesia,
  'status': value.status,
  if (value.audio != null) 'audio': _audioJson(value.audio!),
};
Map<String, Object?> _exampleJson(DictionaryExample value) => {
  'id': value.id,
  'kode': value.code,
  'contoh_mekongga': value.mekongga,
  'contoh_indonesia': value.indonesia,
  'status': value.status,
  if (value.audio != null) 'audio': _audioJson(value.audio!),
};
Map<String, Object?> _audioJson(DictionaryAudio value) => {
  'id': value.id,
  'url': value.url,
  'mime_type': value.mimeType,
  'size_bytes': value.sizeBytes,
  'checksum_sha256': value.checksumSha256,
};

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
