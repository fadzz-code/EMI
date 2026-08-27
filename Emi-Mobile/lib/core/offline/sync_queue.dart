import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.ownerStudentId,
    required this.operationType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    required this.lastError,
    required this.authBlocked,
  });

  final int id;
  final String ownerStudentId;
  final String operationType;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  final bool authBlocked;
}

class SyncQueue {
  SyncQueue(this.database);

  static const maxLastErrorLength = 1000;
  final Database database;

  Future<int> enqueue({
    required String ownerStudentId,
    required String operationType,
    required String entityId,
    required Map<String, Object?> payload,
    DateTime? now,
  }) async {
    _validateOwner(ownerStudentId);
    if (operationType != 'lesson_completed') {
      throw ArgumentError.value(operationType, 'operationType');
    }
    if (entityId.trim().isEmpty) {
      throw ArgumentError.value(entityId, 'entityId');
    }
    final timestamp = (now ?? DateTime.now().toUtc()).toIso8601String();
    return database.transaction((txn) async {
      final existing = await txn.query(
        'sync_queue',
        columns: ['id'],
        where: 'owner_student_id = ? AND operation_type = ? AND entity_id = ?',
        whereArgs: [ownerStudentId, operationType, entityId],
        orderBy: 'id ASC',
        limit: 1,
      );
      if (existing.isNotEmpty) return existing.single['id'] as int;
      await txn.insert('sync_queue', {
        'owner_student_id': ownerStudentId,
        'operation_type': operationType,
        'entity_id': entityId,
        'payload_json': jsonEncode(payload),
        'created_at': timestamp,
        'updated_at': timestamp,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      final inserted = await txn.query(
        'sync_queue',
        columns: ['id'],
        where: 'owner_student_id = ? AND operation_type = ? AND entity_id = ?',
        whereArgs: [ownerStudentId, operationType, entityId],
        limit: 1,
      );
      return inserted.single['id'] as int;
    });
  }

  Future<SyncQueueItem?> next(String ownerStudentId, {DateTime? now}) async {
    _validateOwner(ownerStudentId);
    final rows = await database.query(
      'sync_queue',
      where:
          'owner_student_id = ? AND auth_blocked = 0 AND terminal = 0 AND (next_attempt_at IS NULL OR next_attempt_at <= ?)',
      whereArgs: [
        ownerStudentId,
        (now ?? DateTime.now().toUtc()).toIso8601String(),
      ],
      orderBy: 'created_at ASC, id ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return SyncQueueItem(
      id: row['id'] as int,
      ownerStudentId: row['owner_student_id'] as String,
      operationType: row['operation_type'] as String,
      entityId: row['entity_id'] as String,
      payload:
          jsonDecode(row['payload_json'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(row['created_at'] as String),
      retryCount: row['retry_count'] as int,
      lastError: row['last_error'] as String?,
      authBlocked: (row['auth_blocked'] as int) == 1,
    );
  }

  Future<void> complete(String ownerStudentId, int id) {
    _validateOwner(ownerStudentId);
    return database.delete(
      'sync_queue',
      where: 'owner_student_id = ? AND id = ?',
      whereArgs: [ownerStudentId, id],
    );
  }

  Future<void> retry(
    String ownerStudentId,
    int id, {
    required DateTime nextAttemptAt,
    required String lastError,
    DateTime? now,
  }) {
    _validateOwner(ownerStudentId);
    final boundedError = lastError.length <= maxLastErrorLength
        ? lastError
        : lastError.substring(0, maxLastErrorLength);
    return database.rawUpdate(
      '''UPDATE sync_queue SET retry_count = retry_count + 1, last_error = ?, next_attempt_at = ?, updated_at = ?
WHERE owner_student_id = ? AND id = ? AND auth_blocked = 0''',
      [
        boundedError,
        nextAttemptAt.toUtc().toIso8601String(),
        (now ?? DateTime.now().toUtc()).toIso8601String(),
        ownerStudentId,
        id,
      ],
    );
  }

  Future<void> blockForAuth(String ownerStudentId, int id, {DateTime? now}) {
    _validateOwner(ownerStudentId);
    return database.update(
      'sync_queue',
      {
        'auth_blocked': 1,
        'next_attempt_at': null,
        'updated_at': (now ?? DateTime.now().toUtc()).toIso8601String(),
      },
      where: 'owner_student_id = ? AND id = ?',
      whereArgs: [ownerStudentId, id],
    );
  }

  Future<void> terminate(
    String ownerStudentId,
    int id, {
    required String lastError,
    DateTime? now,
  }) {
    _validateOwner(ownerStudentId);
    final boundedError = lastError.length <= maxLastErrorLength
        ? lastError
        : lastError.substring(0, maxLastErrorLength);
    return database.update(
      'sync_queue',
      {
        'terminal': 1,
        'auth_blocked': 0,
        'last_error': boundedError,
        'next_attempt_at': null,
        'updated_at': (now ?? DateTime.now().toUtc()).toIso8601String(),
      },
      where: 'owner_student_id = ? AND id = ?',
      whereArgs: [ownerStudentId, id],
    );
  }

  Future<void> unblockOwner(String ownerStudentId, {DateTime? now}) {
    _validateOwner(ownerStudentId);
    return database.update(
      'sync_queue',
      {
        'auth_blocked': 0,
        'updated_at': (now ?? DateTime.now().toUtc()).toIso8601String(),
      },
      where: 'owner_student_id = ? AND terminal = 0',
      whereArgs: [ownerStudentId],
    );
  }

  static void _validateOwner(String ownerStudentId) {
    if (ownerStudentId.trim().isEmpty) {
      throw ArgumentError.value(ownerStudentId, 'ownerStudentId');
    }
  }
}
