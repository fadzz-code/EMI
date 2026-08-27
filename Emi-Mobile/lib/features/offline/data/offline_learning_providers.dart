import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/offline/providers.dart';
import '../../dictionary/presentation/dictionary_offline_providers.dart';
import '../../modules/presentation/student_module_offline_providers.dart';
import '../domain/offline_learning_summary.dart';

final offlineLearningSummaryProvider =
    FutureProvider.autoDispose<OfflineLearningSummary>((ref) async {
      final moduleRepo = await ref.watch(offlineModuleRepositoryProvider);
      final dictRepo = await ref.watch(offlineDictionaryRepositoryProvider);
      final dbAsync = await ref.watch(offlineDatabaseProvider);

      final dbFile = File(dbAsync.database.path);
      int dbSize = 0;
      if (await dbFile.exists()) {
        dbSize = await dbFile.length();
      }

      int mediaSize = 0;
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final mediaDir = Directory(p.join(appDir.path, 'media'));
        if (await mediaDir.exists()) {
          mediaSize = await _getDirectorySize(mediaDir);
        }
      } catch (_) {}

      int modules = 0;
      try {
        // Just approximate from updates manifest as offlineModuleRepository doesn't have local list method yet
        final downloaded = await moduleRepo.manifest();
        modules = downloaded.length;
      } catch (_) {}

      int cats = 0;
      try {
        final dictCats = await dictRepo.manifest();
        cats = dictCats.length;
      } catch (_) {}

      int entries = 0;
      try {
        // Note: offline dictionary repo doesn't expose a raw 'entry count' easily without owner ID and full list.
        // We'll leave it as an approximation or 0 unless we run a raw query.
        final countResult = await dbAsync.database.rawQuery(
          "SELECT COUNT(*) AS c FROM dictionary_entries",
        );
        entries = (countResult.first['c'] as int?) ?? 0;
      } catch (_) {}

      final db = dbAsync.database;
      int pending = 0;
      int failed = 0;
      int authBlocked = 0;

      try {
        final queue = await db.query('sync_queue');
        for (final item in queue) {
          final terminal = item['terminal'] as int?;
          final blocked = item['auth_blocked'] as int?;
          if (blocked == 1) {
            authBlocked++;
          } else if (terminal == 1) {
            failed++;
          } else {
            pending++;
          }
        }
      } catch (_) {}

      return OfflineLearningSummary(
        moduleCount: modules,
        categoryCount: cats,
        entryCount: entries,
        pendingActivities: pending,
        failedActivities: failed,
        authBlockedActivities: authBlocked,
        dbSizeBytes: dbSize,
        mediaSizeBytes: mediaSize,
      );
    });

Future<int> _getDirectorySize(Directory dir) async {
  int size = 0;
  try {
    if (await dir.exists()) {
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          size += await file.length();
        }
      }
    }
  } catch (_) {}
  return size;
}
