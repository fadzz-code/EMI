import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/core/offline/offline_database.dart';
import 'package:emi_mobile/core/offline/offline_file_store.dart';
import 'package:emi_mobile/core/offline/sync_executor.dart';
import 'package:emi_mobile/core/offline/sync_queue.dart';
import 'package:emi_mobile/features/modules/data/offline_module_repository.dart';
import 'package:emi_mobile/features/modules/data/student_module_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('offline module download service', () {
    late Directory dir;
    late String dbPath;
    late OfflineDatabase db;
    late OfflineFileStore files;
    late _Api api;
    late OfflineModuleRepository repo;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('emi-offline-');
      dbPath = '${dir.path}${Platform.pathSeparator}db.sqlite';
      db = await OfflineDatabase.open(path: dbPath);
      files = await OfflineFileStore.open(supportDirectory: dir);
      api = _Api();
      repo = _repo(db, files, api);
    });
    tearDown(() async {
      if (db.database.isOpen) await db.close();
      await dir.delete(recursive: true);
    });

    test(
      'persists metadata lessons media, owner isolation, and second repository reopens offline',
      () async {
        await repo.download('a', 'm');
        expect(
          await db.readAll(ownerStudentId: 'a', table: 'offline_modules'),
          hasLength(1),
        );
        expect(
          await db.readAll(ownerStudentId: 'a', table: 'offline_lessons'),
          hasLength(2),
        );
        expect(
          await db.readAll(ownerStudentId: 'a', table: 'offline_media'),
          hasLength(1),
        );
        expect(await repo.local('b', 'm'), isNull);
        await db.close();
        db = await OfflineDatabase.open(path: dbPath);
        final reopened = _repo(db, files, _Api()..offline = true);
        expect((await reopened.local('a', 'm'))?.version, 'v1');
        expect(
          (await reopened.detail('a', 'm', allowFallback: true)).title,
          'Module',
        );
        expect(
          (await reopened.lesson('a', 'media', allowFallback: true)).title,
          'Media',
        );
        await expectLater(
          reopened.detail('b', 'm', allowFallback: true),
          throwsA(isA<AppError>()),
        );
        await expectLater(
          reopened.lesson('b', 'media', allowFallback: true),
          throwsA(isA<AppError>()),
        );
      },
    );

    test(
      'incomplete failure invisible, failed update keeps old, success replaces',
      () async {
        api.failMedia = true;
        await expectLater(repo.download('a', 'm'), throwsA(anything));
        expect(await repo.local('a', 'm'), isNull);
        for (final table in [
          'offline_modules',
          'offline_lessons',
          'offline_media',
          'offline_packages',
        ]) {
          expect(await db.readAll(ownerStudentId: 'a', table: table), isEmpty);
        }
        api.failMedia = false;
        await repo.download('a', 'm');
        api
          ..version = 'v2'
          ..title = 'New'
          ..bytes = [9, 8, 7]
          ..failMedia = true;
        await expectLater(repo.download('a', 'm'), throwsA(anything));
        expect((await repo.local('a', 'm'))?.version, 'v1');
        expect((await repo.local('a', 'm'))?.module.title, 'Module');
        api.failMedia = false;
        await repo.download('a', 'm');
        expect((await repo.local('a', 'm'))?.version, 'v2');
        expect((await repo.local('a', 'm'))?.module.title, 'New');
      },
    );

    test(
      'version detection, remove preserves queue and shared media',
      () async {
        await repo.download('a', 'm');
        api.version = 'v2';
        expect((await repo.updates('a')).single.version, 'v2');
        expect(await repo.updates('b'), isEmpty);
        final row = (await db.readAll(
          ownerStudentId: 'a',
          table: 'offline_media',
        )).single;
        final data =
            jsonDecode(row['data_json'] as String) as Map<String, dynamic>;
        await db.put(
          ownerStudentId: 'a',
          table: 'offline_media',
          id: 'other:shared',
          data: {...data, 'module_id': 'other'},
        );
        final queue = SyncQueue(db.database);
        await queue.enqueue(
          ownerStudentId: 'a',
          operationType: 'lesson_completed',
          entityId: 'media',
          payload: const {},
        );
        await repo.remove('a', 'm');
        expect(await repo.local('a', 'm'), isNull);
        expect(await files.exists('a', data['file_ref'] as String), isTrue);
        expect(await queue.next('a'), isNotNull);
      },
    );
  });

  group('optimistic queue and sync executor', () {
    late Directory dir;
    late String path;
    late OfflineDatabase db;
    late SyncQueue queue;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('emi-sync-');
      path = '${dir.path}${Platform.pathSeparator}db.sqlite';
      db = await OfflineDatabase.open(path: path);
      queue = SyncQueue(db.database);
    });
    tearDown(() async {
      if (db.database.isOpen) await db.close();
      await dir.delete(recursive: true);
    });

    test('completion dedupes and persists across reopen', () async {
      final id = await _enqueue(queue);
      expect(await _enqueue(queue), id);
      expect(await db.database.query('sync_queue'), hasLength(1));
      await db.close();
      db = await OfflineDatabase.open(path: path);
      queue = SyncQueue(db.database);
      expect((await queue.next('a'))?.entityId, 'lesson');
    });

    test('reconnect success removes all', () async {
      await _enqueue(queue);
      await queue.enqueue(
        ownerStudentId: 'a',
        operationType: 'lesson_completed',
        entityId: 'two',
        payload: const {},
      );
      final sender = _Sender();
      await SyncExecutor(queue: queue, sender: sender).run('a');
      expect(sender.sent, ['lesson', 'two']);
      expect(await queue.next('a'), isNull);
    });

    test('transient retains and retries; auth blocks', () async {
      final now = DateTime.utc(2026);
      await _enqueue(queue, now: now);
      final sender = _Sender()
        ..error = const AppError(
          type: AppErrorType.networkUnavailable,
          message: 'offline',
        );
      final executor = SyncExecutor(queue: queue, sender: sender);
      await executor.run('a', now: now);
      final row = (await db.database.query('sync_queue')).single;
      expect(row['retry_count'], 1);
      expect(row['last_error'], 'offline');
      expect(await queue.next('a', now: now), isNull);
      sender.error = null;
      await executor.run('a', now: now.add(const Duration(seconds: 1)));
      expect(await db.database.query('sync_queue'), isEmpty);
      await _enqueue(queue);
      sender.error = const AppError(
        type: AppErrorType.unauthorized,
        message: 'login',
      );
      await executor.run('a');
      expect((await db.database.query('sync_queue')).single['auth_blocked'], 1);
      expect(await queue.next('a'), isNull);
      sender.error = null;
      await queue.unblockOwner('a');
      await executor.run('a');
      expect(await db.database.query('sync_queue'), isEmpty);
    });
  });
}

Future<int> _enqueue(SyncQueue queue, {DateTime? now}) => queue.enqueue(
  ownerStudentId: 'a',
  operationType: 'lesson_completed',
  entityId: 'lesson',
  payload: const {'status': 'completed'},
  now: now,
);
OfflineModuleRepository _repo(
  OfflineDatabase db,
  OfflineFileStore files,
  _Api api,
) => OfflineModuleRepository(
  database: db,
  fileStore: files,
  dio: api.dio,
  remote: StudentModuleRepository(api.dio, const DioErrorMapper()),
);

class _Sender implements LessonCompletionSender {
  final sent = <String>[];
  AppError? error;
  @override
  Future<void> completeLesson(String id) async {
    if (error != null) throw error!;
    sent.add(id);
  }
}

class _Api {
  _Api() {
    dio.httpClientAdapter = _Adapter(this);
  }
  final dio = Dio(BaseOptions(baseUrl: 'https://emi.test'));
  String version = 'v1';
  String title = 'Module';
  List<int> bytes = [1, 2, 3];
  bool failMedia = false;
  bool offline = false;
  String get checksum => sha256.convert(bytes).toString();
  Map<String, dynamic> media() => {
    'id': 'shared',
    'mime_type': 'audio/mpeg',
    'visibility': 'private',
    'size_bytes': bytes.length,
    'checksum_sha256': checksum,
    'extension': 'mp3',
  };
  Map<String, dynamic> lesson(String id, bool hasMedia) => {
    'id': id,
    'class_module_id': 'm',
    'title': hasMedia ? 'Media' : 'Text',
    'content_type': hasMedia ? 'audio' : 'text',
    'content_body': hasMedia ? null : 'Body',
    'sort_order': hasMedia ? 2 : 1,
    'status': 'published',
    if (hasMedia) 'media': media(),
  };
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.api);
  final _Api api;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? stream,
    Future<void>? cancel,
  ) async {
    final path = o.uri.path;
    if (api.offline || (api.failMedia && path == '/media'))
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    if (path == '/media') return ResponseBody.fromBytes(api.bytes, 200);
    Object data;
    if (path == '/student/offline/manifest') {
      data = {
        'data': {
          'schema_version': 1,
          'modules': [
            {'id': 'm', 'version': api.version},
            {'id': 'other', 'version': 'x'},
          ],
        },
      };
    } else if (path == '/student/modules/m') {
      data = {
        'data': {
          'id': 'm',
          'title': api.title,
          'status': 'published',
          'sort_order': 1,
          'progress': {
            'status': 'in_progress',
            'progress_percent': 0,
            'completed_lessons': 0,
            'total_lessons': 2,
          },
          'lessons': [api.lesson('text', false), api.lesson('media', true)],
        },
      };
    } else if (path == '/class-lessons/text') {
      data = {'data': api.lesson('text', false)};
    } else if (path == '/class-lessons/media') {
      data = {'data': api.lesson('media', true)};
    } else if (path == '/class-lessons/media/content-url') {
      data = {
        'data': {'url': 'https://emi.test/media', 'media': api.media()},
      };
    } else {
      return ResponseBody.fromString('', 404);
    }
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
