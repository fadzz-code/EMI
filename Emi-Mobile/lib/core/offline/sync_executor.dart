import 'dart:async';

import '../errors/app_error.dart';
import 'sync_queue.dart';

abstract interface class LessonCompletionSender {
  Future<void> completeLesson(String lessonId);
}

class SyncExecutor {
  SyncExecutor({
    required SyncQueue queue,
    required LessonCompletionSender sender,
  }) : _queue = queue,
       _sender = sender;

  final SyncQueue _queue;
  final LessonCompletionSender _sender;
  final Map<String, Future<void>> _runs = {};

  Future<void> run(String ownerStudentId, {DateTime? now}) => _runs.putIfAbsent(
    ownerStudentId,
    () => _drain(ownerStudentId, now: now).whenComplete(() {
      _runs.remove(ownerStudentId);
    }),
  );

  Future<void> _drain(String ownerStudentId, {DateTime? now}) async {
    while (true) {
      final item = await _queue.next(ownerStudentId, now: now);
      if (item == null) return;
      try {
        await _sender.completeLesson(item.entityId);
        await _queue.complete(ownerStudentId, item.id);
      } on AppError catch (error) {
        if (error.type == AppErrorType.unauthorized) {
          await _queue.blockForAuth(ownerStudentId, item.id, now: now);
          return;
        }
        if (error.type == AppErrorType.forbidden ||
            error.type == AppErrorType.notFound ||
            error.type == AppErrorType.conflict ||
            error.type == AppErrorType.validation) {
          await _queue.terminate(
            ownerStudentId,
            item.id,
            lastError: 'terminal:${error.type.name}:${error.message}',
            now: now,
          );
          continue;
        }
        final delay = Duration(seconds: 1 << item.retryCount.clamp(0, 8));
        await _queue.retry(
          ownerStudentId,
          item.id,
          nextAttemptAt: (now ?? DateTime.now().toUtc()).add(delay),
          lastError: error.message,
          now: now,
        );
        return;
      } catch (error) {
        final delay = Duration(seconds: 1 << item.retryCount.clamp(0, 8));
        await _queue.retry(
          ownerStudentId,
          item.id,
          nextAttemptAt: (now ?? DateTime.now().toUtc()).add(delay),
          lastError: error.toString(),
          now: now,
        );
        return;
      }
    }
  }
}
