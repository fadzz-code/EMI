import 'offline_database.dart';
import 'offline_file_store.dart';

abstract interface class OwnerOfflineDataCleaner {
  Future<void> deleteOwner(String ownerStudentId);
}

class OwnerOfflineDataStore implements OwnerOfflineDataCleaner {
  const OwnerOfflineDataStore({
    required OfflineDatabase database,
    required OfflineFileStore fileStore,
  }) : _database = database,
       _fileStore = fileStore;

  final OfflineDatabase _database;
  final OfflineFileStore _fileStore;

  @override
  Future<void> deleteOwner(String ownerStudentId) async {
    await _database.deleteOwner(ownerStudentId);
    await _fileStore.deleteOwner(ownerStudentId);
  }
}
