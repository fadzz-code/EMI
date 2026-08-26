import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class OfflineFileStore {
  OfflineFileStore._(this.root);

  static int _partialSequence = 0;
  final Directory root;

  static Future<OfflineFileStore> open({Directory? supportDirectory}) async {
    final support = supportDirectory ?? await getApplicationSupportDirectory();
    return OfflineFileStore._(Directory(p.join(support.path, 'offline_media')));
  }

  String pathFor(String ownerStudentId, String mediaId) {
    _validate(ownerStudentId, 'ownerStudentId');
    _validate(mediaId, 'mediaId');
    return p.join(root.path, _encode(ownerStudentId), _encode(mediaId));
  }

  Future<File> write(
    String ownerStudentId,
    String mediaId,
    List<int> bytes,
  ) async {
    final target = File(pathFor(ownerStudentId, mediaId));
    await target.parent.create(recursive: true);
    final partial = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.${_partialSequence++}.partial',
    );
    try {
      await partial.writeAsBytes(bytes, flush: true);
      try {
        return await partial.rename(target.path);
      } on FileSystemException {
        if (!await target.exists()) rethrow;
        await target.delete();
        return await partial.rename(target.path);
      }
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  Future<bool> exists(String ownerStudentId, String mediaId) =>
      File(pathFor(ownerStudentId, mediaId)).exists();

  Future<void> delete(String ownerStudentId, String mediaId) async {
    final file = File(pathFor(ownerStudentId, mediaId));
    if (await file.exists()) await file.delete();
  }

  Future<void> deleteOwner(String ownerStudentId) async {
    _validate(ownerStudentId, 'ownerStudentId');
    final directory = Directory(p.join(root.path, _encode(ownerStudentId)));
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  static String _encode(String value) =>
      Uri.encodeComponent(value).replaceAll('.', '%2E');

  static void _validate(String value, String name) {
    if (value.trim().isEmpty) throw ArgumentError.value(value, name);
  }
}
