import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const offlineDatabaseVersion = 2;

class OfflineDatabase {
  OfflineDatabase(this.database);

  final Database database;

  static const contentTables = <String>{
    'offline_packages',
    'offline_media',
    'offline_modules',
    'offline_lessons',
    'offline_dictionary_entries',
    'offline_dictionary_sentences',
  };

  static Future<OfflineDatabase> open({String? path}) async {
    final databasePath =
        path ?? p.join(await getDatabasesPath(), 'emi_offline.db');
    return OfflineDatabase(
      await openDatabase(
        databasePath,
        version: offlineDatabaseVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => migrate(db, 0, version),
        onUpgrade: migrate,
      ),
    );
  }

  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1 && newVersion >= 1) {
      for (final table in contentTables) {
        await db.execute('''
CREATE TABLE $table (
  owner_student_id TEXT NOT NULL,
  id TEXT NOT NULL,
  data_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (owner_student_id, id)
)''');
        await db.execute(
          'CREATE INDEX ${table}_owner_updated_idx ON $table (owner_student_id, updated_at)',
        );
      }
      await db.execute('''
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_student_id TEXT NOT NULL,
  operation_type TEXT NOT NULL CHECK (operation_type = 'lesson_completed'),
  entity_id TEXT NOT NULL CHECK (length(trim(entity_id)) > 0),
  payload_json TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  next_attempt_at TEXT,
  auth_blocked INTEGER NOT NULL DEFAULT 0 CHECK (auth_blocked IN (0, 1))
)''');
      await db.execute(
        'CREATE INDEX sync_queue_owner_fifo_idx ON sync_queue (owner_student_id, auth_blocked, created_at, id)',
      );
    }
    if (oldVersion < 2 && newVersion >= 2) {
      await db.execute('''DELETE FROM sync_queue WHERE id NOT IN (
SELECT MIN(id) FROM sync_queue GROUP BY owner_student_id, operation_type, entity_id
)''');
      await db.execute(
        'CREATE UNIQUE INDEX sync_queue_logical_unique_idx ON sync_queue (owner_student_id, operation_type, entity_id)',
      );
    }
  }

  Future<void> put({
    required String ownerStudentId,
    required String table,
    required String id,
    required Map<String, Object?> data,
    DateTime? now,
  }) async {
    _validateOwner(ownerStudentId);
    _validateContentTable(table);
    final timestamp = (now ?? DateTime.now().toUtc()).toIso8601String();
    await database.rawInsert(
      '''INSERT INTO $table (owner_student_id, id, data_json, created_at, updated_at)
VALUES (?, ?, ?, ?, ?)
ON CONFLICT(owner_student_id, id) DO UPDATE SET data_json = excluded.data_json, updated_at = excluded.updated_at''',
      [ownerStudentId, id, jsonEncode(data), timestamp, timestamp],
    );
  }

  Future<List<Map<String, Object?>>> readAll({
    required String ownerStudentId,
    required String table,
  }) async {
    _validateOwner(ownerStudentId);
    _validateContentTable(table);
    return database.query(
      table,
      where: 'owner_student_id = ?',
      whereArgs: [ownerStudentId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<void> deleteOwner(String ownerStudentId) async {
    _validateOwner(ownerStudentId);
    await database.transaction((txn) async {
      for (final table in {...contentTables, 'sync_queue'}) {
        await txn.delete(
          table,
          where: 'owner_student_id = ?',
          whereArgs: [ownerStudentId],
        );
      }
    });
  }

  Future<void> close() => database.close();

  static void _validateOwner(String owner) {
    if (owner.trim().isEmpty) {
      throw ArgumentError.value(owner, 'ownerStudentId');
    }
  }

  static void _validateContentTable(String table) {
    if (!contentTables.contains(table)) {
      throw ArgumentError.value(table, 'table');
    }
  }
}
