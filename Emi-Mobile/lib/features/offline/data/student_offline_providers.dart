import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../modules/presentation/student_module_offline_providers.dart';

class StudentOfflineSummary {
  const StudentOfflineSummary({
    required this.modules,
    required this.dictionaryCategories,
    required this.dictionaryEntries,
    required this.pendingSync,
    required this.failedSync,
    required this.authBlocked,
    required this.mediaBytes,
    required this.databaseBytes,
  });

  final int modules;
  final int dictionaryCategories;
  final int dictionaryEntries;
  final int pendingSync;
  final int failedSync;
  final bool authBlocked;
  final int mediaBytes;
  final int databaseBytes;
  int get usedBytes => mediaBytes + databaseBytes;
}

final studentOfflineSummaryProvider = FutureProvider.autoDispose<StudentOfflineSummary>((
  ref,
) async {
  final owner = ref.watch(authControllerProvider).user?.id;
  if (owner == null) throw StateError('Siswa belum terautentikasi.');
  final offline = await ref.watch(offlineDatabaseProvider);
  final db = offline.database;
  Future<int> count(String table, [String? extra]) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $table WHERE owner_student_id = ?${extra ?? ''}',
      [owner],
    );
    return (rows.single['total'] as num?)?.toInt() ?? 0;
  }

  final packages = await db.rawQuery(
    "SELECT COUNT(*) AS total FROM offline_packages WHERE owner_student_id = ? AND json_extract(data_json, '\$.kind') = 'module'",
    [owner],
  );
  final categories = await db.rawQuery(
    'SELECT COUNT(DISTINCT category_id) AS total FROM offline_dictionary_entries WHERE owner_student_id = ?',
    [owner],
  );
  final sync = await db.rawQuery(
    '''SELECT COUNT(*) AS total,
SUM(CASE WHEN retry_count > 0 THEN 1 ELSE 0 END) AS failed,
MAX(auth_blocked) AS blocked FROM sync_queue WHERE owner_student_id = ?''',
    [owner],
  );
  final fileStore = await ref.watch(offlineFileStoreProvider);
  final ownerDirectory = Directory(
    Uri.decodeComponent(
      fileStore.pathFor(owner, 'x'),
    ).replaceFirst(RegExp(r'[\\/]x$'), ''),
  );
  var mediaBytes = 0;
  if (await ownerDirectory.exists()) {
    await for (final entity in ownerDirectory.list(recursive: true)) {
      if (entity is File) mediaBytes += await entity.length();
    }
  }
  var databaseBytes = 0;
  for (final suffix in ['', '-wal', '-shm']) {
    final file = File('${db.path}$suffix');
    if (await file.exists()) databaseBytes += await file.length();
  }
  final syncRow = sync.single;
  return StudentOfflineSummary(
    modules: (packages.single['total'] as num?)?.toInt() ?? 0,
    dictionaryCategories: (categories.single['total'] as num?)?.toInt() ?? 0,
    dictionaryEntries: await count('offline_dictionary_entries'),
    pendingSync: (syncRow['total'] as num?)?.toInt() ?? 0,
    failedSync: (syncRow['failed'] as num?)?.toInt() ?? 0,
    authBlocked: ((syncRow['blocked'] as num?)?.toInt() ?? 0) == 1,
    mediaBytes: mediaBytes,
    databaseBytes: databaseBytes,
  );
});

Future<void> syncStudentOffline(WidgetRef ref) async {
  await ref.read(moduleSyncCoordinatorProvider).trigger();
  ref.invalidate(studentOfflineSummaryProvider);
}

String formatOfflineBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
