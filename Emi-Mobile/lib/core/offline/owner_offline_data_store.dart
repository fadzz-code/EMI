import 'offline_database.dart';
import 'offline_file_store.dart';
import 'owner_lifecycle.dart';

abstract interface class OwnerOfflineDataCleaner {
  Future<void> deleteOwner(String ownerStudentId);
}

class OwnerOfflineDataStore implements OwnerOfflineDataCleaner {
  const OwnerOfflineDataStore({
    required OfflineDatabase database,
    required OfflineFileStore fileStore,
    OwnerLifecycle? lifecycle,
  }) : _database = database,
       _fileStore = fileStore,
       _lifecycle = lifecycle;

  final OfflineDatabase _database;
  final OfflineFileStore _fileStore;
  final OwnerLifecycle? _lifecycle;

  @override
  Future<void> deleteOwner(String ownerStudentId) async {
    _lifecycle?.invalidate(ownerStudentId);
    Object? firstError;
    try {
      await _database.deleteOwner(ownerStudentId);
    } catch (error) {
      firstError = error;
    }
    try {
      await _fileStore.deleteOwner(ownerStudentId);
    } catch (error) {
      firstError ??= error;
    }
    if (firstError != null) throw firstError;
  }
}
