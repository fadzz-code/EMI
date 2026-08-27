import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:emi_mobile/core/network/network_status_controller.dart';
import 'package:emi_mobile/core/offline/offline_database.dart';
import 'package:emi_mobile/core/offline/offline_file_store.dart';
import 'package:emi_mobile/core/offline/owner_lifecycle.dart';
import 'package:emi_mobile/core/offline/owner_offline_data_store.dart';
import 'package:emi_mobile/core/offline/sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Connectivity extends Mock implements Connectivity {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late OfflineDatabase offline;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    offline = await OfflineDatabase.open(path: inMemoryDatabasePath);
  });

  tearDown(() => offline.close());

  test('schema versions content and enforces owner-scoped reads', () async {
    expect(await offline.database.getVersion(), offlineDatabaseVersion);
    for (final table in OfflineDatabase.contentTables) {
      final columns = await offline.database.rawQuery(
        'PRAGMA table_info($table)',
      );
      expect(
        columns.map((row) => row['name']),
        containsAll(['owner_student_id', 'created_at', 'updated_at']),
      );
    }

    await offline.put(
      ownerStudentId: 'student-a',
      table: 'offline_lessons',
      id: 'lesson-1',
      data: {'title': 'A'},
    );
    await offline.put(
      ownerStudentId: 'student-b',
      table: 'offline_lessons',
      id: 'lesson-1',
      data: {'title': 'B'},
    );

    expect(
      await offline.readAll(
        ownerStudentId: 'student-a',
        table: 'offline_lessons',
      ),
      hasLength(1),
    );
    expect(
      () => offline.readAll(ownerStudentId: '', table: 'offline_lessons'),
      throwsArgumentError,
    );
  });

  test(
    'sync queue is owner FIFO, validates operation, and blocks auth',
    () async {
      final queue = SyncQueue(offline.database);
      final first = await queue.enqueue(
        ownerStudentId: 'student-a',
        operationType: 'lesson_completed',
        entityId: 'one',
        payload: {'lesson_id': 'one'},
        now: DateTime.utc(2026),
      );
      await queue.enqueue(
        ownerStudentId: 'student-a',
        operationType: 'lesson_completed',
        entityId: 'two',
        payload: {'lesson_id': 'two'},
        now: DateTime.utc(2026, 1, 2),
      );
      expect((await queue.next('student-a'))!.id, first);
      await queue.blockForAuth('student-a', first);
      expect((await queue.next('student-a'))!.payload['lesson_id'], 'two');
      await queue.retry(
        'student-a',
        first,
        nextAttemptAt: DateTime.utc(2026, 2),
        lastError: 'unauthorized',
      );
      final blocked = await offline.database.query(
        'sync_queue',
        where: 'id = ?',
        whereArgs: [first],
      );
      expect(blocked.single['retry_count'], 0);
      expect(
        () => queue.enqueue(
          ownerStudentId: 'student-a',
          operationType: 'unknown',
          entityId: 'lesson',
          payload: const {},
        ),
        throwsArgumentError,
      );
    },
  );

  test('v2 migration dedupes queue and adds logical unique index', () async {
    final directory = await Directory.systemTemp.createTemp('emi-v2-test');
    addTearDown(() => directory.delete(recursive: true));
    final db = await databaseFactoryFfi.openDatabase(
      '${directory.path}${Platform.pathSeparator}migration.db',
    );
    addTearDown(db.close);
    await OfflineDatabase.migrate(db, 0, 1);
    final row = {
      'owner_student_id': 'student-a',
      'operation_type': 'lesson_completed',
      'entity_id': 'lesson-1',
      'payload_json': '{}',
      'created_at': DateTime.utc(2026).toIso8601String(),
      'updated_at': DateTime.utc(2026).toIso8601String(),
    };
    await db.insert('sync_queue', row);
    await db.insert('sync_queue', row);
    await OfflineDatabase.migrate(db, 1, 2);
    expect(await db.query('sync_queue'), hasLength(1));
    expect(() => db.insert('sync_queue', row), throwsA(anything));
  });

  test('v1 migration creates exact queue schema', () async {
    final directory = await Directory.systemTemp.createTemp(
      'emi-migration-test',
    );
    addTearDown(() => directory.delete(recursive: true));
    final db = await databaseFactoryFfi.openDatabase(
      '${directory.path}${Platform.pathSeparator}migration.db',
    );
    addTearDown(db.close);
    await OfflineDatabase.migrate(db, 0, 1);
    final columns = await db.rawQuery('PRAGMA table_info(sync_queue)');
    expect(
      columns.map((row) => row['name']),
      containsAll([
        'id',
        'owner_student_id',
        'operation_type',
        'entity_id',
        'payload_json',
        'created_at',
        'updated_at',
        'retry_count',
        'last_error',
      ]),
    );
    expect(columns.map((row) => row['name']), isNot(contains('operation')));
  });

  test(
    'queue exposes fields, validates entity, scopes retry, and bounds error',
    () async {
      final queue = SyncQueue(offline.database);
      final created = DateTime.utc(2026, 3);
      final id = await queue.enqueue(
        ownerStudentId: 'student-a',
        operationType: 'lesson_completed',
        entityId: 'lesson-1',
        payload: const {},
        now: created,
      );
      await queue.retry(
        'student-b',
        id,
        nextAttemptAt: DateTime.utc(2026, 4),
        lastError: 'wrong owner',
      );
      await queue.retry(
        'student-a',
        id,
        nextAttemptAt: DateTime.utc(2025),
        lastError: 'x' * 1200,
      );
      final item = await queue.next('student-a', now: DateTime.utc(2026));
      expect(item!.operationType, 'lesson_completed');
      expect(item.entityId, 'lesson-1');
      expect(item.createdAt, created);
      expect(item.retryCount, 1);
      expect(item.lastError, hasLength(SyncQueue.maxLastErrorLength));
      expect(
        () => queue.enqueue(
          ownerStudentId: 'student-a',
          operationType: 'lesson_completed',
          entityId: '  ',
          payload: const {},
        ),
        throwsArgumentError,
      );
    },
  );

  test('owner cleanup removes A database and files but preserves B', () async {
    final temporary = await Directory.systemTemp.createTemp('emi-owner-test');
    addTearDown(() => temporary.delete(recursive: true));
    final files = await OfflineFileStore.open(supportDirectory: temporary);
    for (final owner in ['student-a', 'student-b']) {
      await offline.put(
        ownerStudentId: owner,
        table: 'offline_lessons',
        id: 'lesson',
        data: const {},
      );
      await files.write(owner, 'media', [1]);
    }

    final lifecycle = OwnerLifecycle();

    await OwnerOfflineDataStore(
      database: offline,
      fileStore: files,
      lifecycle: lifecycle,
    ).deleteOwner('student-a');

    expect(lifecycle.generation('student-a'), 1);
    expect(lifecycle.generation('student-b'), 0);

    expect(
      await offline.readAll(
        ownerStudentId: 'student-a',
        table: 'offline_lessons',
      ),
      isEmpty,
    );
    expect(
      await offline.readAll(
        ownerStudentId: 'student-b',
        table: 'offline_lessons',
      ),
      hasLength(1),
    );
    expect(await files.exists('student-a', 'media'), isFalse);
    expect(await files.exists('student-b', 'media'), isTrue);
  });

  test('stale probe cannot overwrite newer offline event', () async {
    final connectivity = _Connectivity();
    final completer = Completer<Response<void>>();
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          handler.resolve(await completer.future);
        },
      ),
    );
    final controller = NetworkStatusController(
      connectivity: connectivity,
      dio: dio,
    );
    final probe = controller.check([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    await controller.check([ConnectivityResult.none]);
    completer.complete(
      Response(requestOptions: RequestOptions(), statusCode: 200),
    );
    await probe;
    expect(controller.mode, NetworkMode.offline);
    controller.dispose();
  });

  test(
    'v4 migration extracts package ids and drops terminal queue entries from retry loop',
    () async {
      final directory = await Directory.systemTemp.createTemp('emi-v4-test');
      addTearDown(() => directory.delete(recursive: true));
      final db = await databaseFactoryFfi.openDatabase(
        '${directory.path}${Platform.pathSeparator}migration.db',
      );
      addTearDown(db.close);
      await OfflineDatabase.migrate(db, 0, 3);
      await db.insert('sync_queue', {
        'owner_student_id': 'student-a',
        'operation_type': 'lesson_completed',
        'entity_id': 'lesson-1',
        'payload_json': '{}',
        'created_at': DateTime.utc(2026).toIso8601String(),
        'updated_at': DateTime.utc(2026).toIso8601String(),
        'last_error': 'terminal:unauthorized:rejected',
      });
      await db.insert('offline_packages', {
        'owner_student_id': 'student-a',
        'id': 'abc',
        'data_json': '{"kind": "module"}',
        'created_at': DateTime.utc(2026).toIso8601String(),
        'updated_at': DateTime.utc(2026).toIso8601String(),
      });

      await OfflineDatabase.migrate(db, 3, 4);

      final queue = await db.query('sync_queue');
      expect(queue.single['terminal'], 1);
      expect(queue.single['auth_blocked'], 0);

      final packages = await db.query('offline_packages');
      expect(packages.single['id'], 'module:abc');
    },
  );

  test(
    'file store encodes paths, atomically completes, and deletes owner',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'emi-offline-test',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final store = await OfflineFileStore.open(supportDirectory: temporary);

      final incompletePath = store.pathFor('owner/one', 'incomplete');
      await File('$incompletePath.orphan.partial').create(recursive: true);
      expect(await store.exists('owner/one', 'incomplete'), isFalse);

      final writes = await Future.wait([
        store.write('owner/one', '../media', [1, 2, 3]),
        store.write('owner/one', '../media', [4, 5, 6]),
      ]);
      final file = writes.last;

      expect(file.path, isNot(contains('../media')));
      expect(await store.exists('owner/one', '../media'), isTrue);
      expect(
        await file.readAsBytes(),
        anyOf(equals([1, 2, 3]), equals([4, 5, 6])),
      );
      final partials = file.parent.listSync().where(
        (entry) => entry.path.endsWith('.partial'),
      );
      expect(partials, hasLength(1));
      await store.deleteOwner('owner/one');
      expect(await store.exists('owner/one', '../media'), isFalse);
    },
  );
}
