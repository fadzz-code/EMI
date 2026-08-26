import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/offline/offline_database.dart';
import '../../../core/offline/offline_file_store.dart';
import 'student_module.dart';
import 'student_module_repository.dart';

class OfflineModulePackage {
  const OfflineModulePackage({
    required this.module,
    required this.version,
    required this.downloadedAt,
  });
  final StudentModule module;
  final String version;
  final DateTime downloadedAt;
}

class OfflineModuleUpdate {
  const OfflineModuleUpdate({required this.moduleId, required this.version});
  final String moduleId;
  final String version;
}

class OfflineModuleRepository {
  const OfflineModuleRepository({
    required OfflineDatabase database,
    required OfflineFileStore fileStore,
    required Dio dio,
    required StudentModuleRepository remote,
  }) : _database = database,
       _fileStore = fileStore,
       _dio = dio,
       _remote = remote;

  final OfflineDatabase _database;
  final OfflineFileStore _fileStore;
  final Dio _dio;
  final StudentModuleRepository _remote;
  static final _downloads = <String, Future<OfflineModulePackage>>{};

  Future<OfflineModulePackage> download(String owner, String moduleId) {
    _validate(owner, 'ownerStudentId');
    final key = '${identityHashCode(this)}:$owner:$moduleId';
    return _downloads.putIfAbsent(
      key,
      () => _download(owner, moduleId).whenComplete(() {
        _downloads.remove(key);
      }),
    );
  }

  Future<OfflineModulePackage> _download(String owner, String moduleId) async {
    _validate(owner, 'ownerStudentId');
    final version = (await manifest())
        .where((value) => value.moduleId == moduleId)
        .firstOrNull
        ?.version;
    if (version == null) {
      throw StateError('Modul tidak tersedia untuk offline.');
    }
    final detail = await _remote.detail(moduleId);
    final lessons = <StudentLesson>[];
    final media = <_DownloadedMedia>[];
    try {
      for (final summary in detail.lessons.where(
        (value) => value.status == 'published',
      )) {
        final lesson = await _remote.lesson(summary.id);
        lessons.add(lesson);
        if (lesson.media == null) continue;
        final content = await _remote.lessonContent(lesson.id);
        final metadata = content?.media;
        if (content == null ||
            !content.hasUrl ||
            metadata == null ||
            metadata.sizeBytes == null ||
            metadata.checksumSha256 == null) {
          throw StateError('Metadata media lesson ${lesson.id} tidak lengkap.');
        }
        final ref = _fileStore.immutableRef(
          metadata.id,
          metadata.checksumSha256!,
        );
        final file = File(_fileStore.pathFor(owner, ref));
        if (!await _valid(
          file,
          metadata.sizeBytes!,
          metadata.checksumSha256!,
        )) {
          await file.parent.create(recursive: true);
          final staged = File(
            '${file.path}.${DateTime.now().microsecondsSinceEpoch}.staging',
          );
          try {
            final response = await _dio.get<ResponseBody>(
              content.url!,
              options: Options(responseType: ResponseType.stream),
            );
            final sink = staged.openWrite();
            try {
              await sink.addStream(response.data!.stream);
            } finally {
              await sink.close();
            }
            if (!await _valid(
              staged,
              metadata.sizeBytes!,
              metadata.checksumSha256!,
            )) {
              throw StateError('Checksum media ${metadata.id} tidak valid.');
            }
            await _fileStore.write(owner, ref, await staged.readAsBytes());
          } finally {
            if (await staged.exists()) await staged.delete();
          }
        }
        media.add(_DownloadedMedia(metadata: metadata, ref: ref));
      }
      final module = StudentModule(
        id: detail.id,
        title: detail.title,
        description: detail.description,
        status: detail.status,
        sortOrder: detail.sortOrder,
        progress: detail.progress,
        lessons: lessons,
      );
      final currentVersion = (await manifest())
          .where((value) => value.moduleId == moduleId)
          .firstOrNull
          ?.version;
      if (currentVersion != version) {
        throw StateError('Modul berubah saat diunduh. Silakan coba lagi.');
      }
      final oldRefs = await _moduleRefs(owner, moduleId);
      final now = DateTime.now().toUtc();
      await _database.database.transaction((txn) async {
        await _deleteRows(txn, owner, moduleId);
        await _put(txn, 'offline_modules', owner, moduleId, {
          'module': _moduleJson(module),
          'version': version,
        }, now);
        for (final lesson in lessons) {
          await _put(txn, 'offline_lessons', owner, lesson.id, {
            'module_id': moduleId,
            'lesson': _lessonJson(lesson),
          }, now);
        }
        for (final value in media) {
          await _put(txn, 'offline_media', owner, '$moduleId:${value.ref}', {
            'module_id': moduleId,
            'file_ref': value.ref,
            'media': _mediaJson(value.metadata),
          }, now);
        }
        await _put(txn, 'offline_packages', owner, moduleId, {
          'kind': 'module',
          'version': version,
          'downloaded_at': now.toIso8601String(),
        }, now);
      });
      for (final ref in oldRefs.where(
        (ref) => !media.any((value) => value.ref == ref),
      )) {
        if (!await _refUsed(owner, ref)) await _fileStore.delete(owner, ref);
      }
      return OfflineModulePackage(
        module: module,
        version: version,
        downloadedAt: now,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<OfflineModulePackage?> local(String owner, String moduleId) async {
    _validate(owner, 'ownerStudentId');
    final modules = await _database.database.query(
      'offline_modules',
      where: 'owner_student_id = ? AND id = ?',
      whereArgs: [owner, moduleId],
      limit: 1,
    );
    final packages = await _database.database.query(
      'offline_packages',
      where: 'owner_student_id = ? AND id = ?',
      whereArgs: [owner, moduleId],
      limit: 1,
    );
    if (modules.isEmpty || packages.isEmpty) return null;
    final media = await _database.database.query(
      'offline_media',
      where: 'owner_student_id = ?',
      whereArgs: [owner],
    );
    for (final row in media) {
      final data = _decode(row);
      if (data['module_id'] == moduleId &&
          !await _fileStore.exists(owner, data['file_ref'] as String)) {
        return null;
      }
    }
    final data = _decode(modules.single);
    final package = _decode(packages.single);
    return OfflineModulePackage(
      module: StudentModule.fromJson(data['module'] as Map<String, dynamic>),
      version: data['version'] as String,
      downloadedAt: DateTime.parse(package['downloaded_at'] as String),
    );
  }

  Future<StudentModule> detail(
    String owner,
    String moduleId, {
    required bool allowFallback,
  }) async {
    try {
      return await _remote.detail(moduleId);
    } on AppError catch (error) {
      if (!allowFallback || !_transport(error)) rethrow;
      final value = await local(owner, moduleId);
      if (value == null) rethrow;
      return value.module;
    }
  }

  Future<StudentLesson> lesson(
    String owner,
    String lessonId, {
    required bool allowFallback,
  }) async {
    try {
      return await _remote.lesson(lessonId);
    } on AppError catch (error) {
      if (!allowFallback || !_transport(error)) rethrow;
      final rows = await _database.database.query(
        'offline_lessons',
        where: 'owner_student_id = ? AND id = ?',
        whereArgs: [owner, lessonId],
        limit: 1,
      );
      if (rows.isEmpty) rethrow;
      return StudentLesson.fromJson(
        _decode(rows.single)['lesson'] as Map<String, dynamic>,
      );
    }
  }

  Future<LessonContent?> content(
    String owner,
    String lessonId, {
    required bool allowFallback,
  }) async {
    try {
      return await _remote.lessonContent(lessonId);
    } on AppError catch (error) {
      if (!allowFallback || !_transport(error)) rethrow;
      final lessons = await _database.database.query(
        'offline_lessons',
        where: 'owner_student_id = ? AND id = ?',
        whereArgs: [owner, lessonId],
        limit: 1,
      );
      if (lessons.isEmpty) rethrow;
      final lesson = StudentLesson.fromJson(
        _decode(lessons.single)['lesson'] as Map<String, dynamic>,
      );
      if (lesson.media == null) {
        return LessonContent(
          type: lesson.contentType,
          contentBody: lesson.contentBody,
          url: lesson.externalUrl,
        );
      }
      final rows = await _database.database.query(
        'offline_media',
        where: 'owner_student_id = ?',
        whereArgs: [owner],
      );
      for (final row in rows) {
        final data = _decode(row);
        final media = data['media'] as Map<String, dynamic>;
        if (media['id'] != lesson.media!.id) continue;
        final ref = data['file_ref'] as String;
        final file = File(_fileStore.pathFor(owner, ref));
        final metadata = LessonMedia.fromJson(media);
        if (!await _valid(
          file,
          metadata.sizeBytes!,
          metadata.checksumSha256!,
        )) {
          rethrow;
        }
        return LessonContent(
          type: lesson.contentType,
          url: file.uri.toString(),
          media: metadata,
        );
      }
      rethrow;
    }
  }

  Future<List<String>> _moduleRefs(String owner, String moduleId) async {
    final rows = await _database.database.query(
      'offline_media',
      where: 'owner_student_id = ?',
      whereArgs: [owner],
    );
    return rows
        .map(_decode)
        .where((data) => data['module_id'] == moduleId)
        .map((data) => data['file_ref'] as String)
        .toList();
  }

  Future<bool> _refUsed(String owner, String ref) async {
    final rows = await _database.database.query(
      'offline_media',
      where: 'owner_student_id = ?',
      whereArgs: [owner],
    );
    return rows.any((row) => _decode(row)['file_ref'] == ref);
  }

  Future<List<OfflineModuleUpdate>> updates(String owner) async {
    final remote = await manifest();
    final rows = await _database.readAll(
      ownerStudentId: owner,
      table: 'offline_packages',
    );
    final local = <String, String>{
      for (final row in rows)
        if (_decode(row)['kind'] == 'module')
          row['id'] as String: _decode(row)['version'] as String,
    };
    return remote
        .where(
          (value) =>
              local[value.moduleId] != null &&
              local[value.moduleId] != value.version,
        )
        .toList();
  }

  Future<List<OfflineModuleUpdate>> manifest() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/student/offline/manifest',
    );
    final data = response.data?['data'];
    if (data is! Map<String, dynamic> ||
        data['schema_version'] != 1 ||
        data['modules'] is! List) {
      throw StateError('Manifest offline tidak valid.');
    }
    return (data['modules'] as List)
        .whereType<Map<String, dynamic>>()
        .map(
          (value) => OfflineModuleUpdate(
            moduleId: value['id'] as String,
            version: value['version'] as String,
          ),
        )
        .toList();
  }

  Future<void> remove(String owner, String moduleId) async {
    final refs = <String>[];
    await _database.database.transaction((txn) async {
      final rows = await txn.query(
        'offline_media',
        where: 'owner_student_id = ?',
        whereArgs: [owner],
      );
      for (final row in rows) {
        final data = _decode(row);
        if (data['module_id'] == moduleId) refs.add(data['file_ref'] as String);
      }
      await _deleteRows(txn, owner, moduleId);
    });
    for (final ref in refs) {
      final rows = await _database.database.query(
        'offline_media',
        where: 'owner_student_id = ?',
        whereArgs: [owner],
      );
      if (!rows.any((row) => _decode(row)['file_ref'] == ref)) {
        await _fileStore.delete(owner, ref);
      }
    }
  }

  static bool _transport(AppError error) =>
      error.type == AppErrorType.networkUnavailable ||
      error.type == AppErrorType.timeout ||
      error.type == AppErrorType.server;
  static Future<bool> _valid(File file, int size, String checksum) async =>
      await file.exists() &&
      await file.length() == size &&
      sha256.convert(await file.readAsBytes()).toString() ==
          checksum.toLowerCase();
  static Map<String, dynamic> _decode(Map<String, Object?> row) =>
      jsonDecode(row['data_json'] as String) as Map<String, dynamic>;

  static Future<void> _deleteRows(
    Transaction txn,
    String owner,
    String moduleId,
  ) async {
    for (final table in ['offline_packages', 'offline_modules']) {
      await txn.delete(
        table,
        where: 'owner_student_id = ? AND id = ?',
        whereArgs: [owner, moduleId],
      );
    }
    for (final table in ['offline_lessons', 'offline_media']) {
      final rows = await txn.query(
        table,
        where: 'owner_student_id = ?',
        whereArgs: [owner],
      );
      for (final row in rows) {
        if (_decode(row)['module_id'] == moduleId) {
          await txn.delete(
            table,
            where: 'owner_student_id = ? AND id = ?',
            whereArgs: [owner, row['id']],
          );
        }
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
  static Map<String, Object?> _moduleJson(StudentModule value) => {
    'id': value.id,
    'title': value.title,
    'description': value.description,
    'status': value.status,
    'sort_order': value.sortOrder,
    'progress': {
      'status': value.progress.status,
      'progress_percent': value.progress.progressPercent,
      'completed_lessons': value.progress.completedLessons,
      'total_lessons': value.progress.totalLessons,
    },
    'lessons': value.lessons.map(_lessonJson).toList(),
  };
  static Map<String, Object?> _lessonJson(StudentLesson value) => {
    'id': value.id,
    'class_module_id': value.classModuleId,
    'title': value.title,
    'description': value.description,
    'content_type': value.contentType,
    'content_body': value.contentBody,
    'external_url': value.externalUrl,
    'sort_order': value.sortOrder,
    'status': value.status,
    if (value.media != null) 'media': _mediaJson(value.media!),
  };
  static Map<String, Object?> _mediaJson(LessonMedia value) => {
    'id': value.id,
    'mime_type': value.mimeType,
    'visibility': value.visibility,
    'size_bytes': value.sizeBytes,
    'checksum_sha256': value.checksumSha256,
    'extension': value.extension,
    'updated_at': value.updatedAt?.toIso8601String(),
  };
  static void _validate(String value, String name) {
    if (value.trim().isEmpty) throw ArgumentError.value(value, name);
  }
}

class _DownloadedMedia {
  const _DownloadedMedia({required this.metadata, required this.ref});
  final LessonMedia metadata;
  final String ref;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
