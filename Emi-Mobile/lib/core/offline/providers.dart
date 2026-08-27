import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_database.dart';
import 'offline_file_store.dart';
import 'owner_lifecycle.dart';
import 'owner_offline_data_store.dart';
import 'sync_queue.dart';

final offlineDatabaseProvider = Provider<Future<OfflineDatabase>>((ref) {
  final future = OfflineDatabase.open();
  ref.onDispose(() async => (await future).close());
  return future;
});

final offlineFileStoreProvider = Provider<Future<OfflineFileStore>>(
  (ref) => OfflineFileStore.open(),
);

final syncQueueProvider = Provider<Future<SyncQueue>>(
  (ref) async => SyncQueue((await ref.watch(offlineDatabaseProvider)).database),
);

final ownerLifecycleProvider = Provider<OwnerLifecycle>(
  (ref) => OwnerLifecycle(),
);

final ownerOfflineDataStoreProvider = Provider<Future<OwnerOfflineDataStore>>(
  (ref) async => OwnerOfflineDataStore(
    database: await ref.watch(offlineDatabaseProvider),
    fileStore: await ref.watch(offlineFileStoreProvider),
    lifecycle: ref.watch(ownerLifecycleProvider),
  ),
);
