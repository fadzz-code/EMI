import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'dictionary_entry.dart';
import 'dictionary_repository.dart';

final dictionaryRepositoryProvider = Provider<DictionaryRepository>(
  (ref) => DictionaryRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

class DictionaryQuery {
  const DictionaryQuery({this.search, this.categoryId});

  final String? search;
  final String? categoryId;
}

final dictionaryListProvider = FutureProvider.autoDispose
    .family<DictionaryPage, DictionaryQuery>(
      (ref, query) => ref
          .watch(dictionaryRepositoryProvider)
          .list(search: query.search, categoryId: query.categoryId),
    );

final dictionaryDetailProvider = FutureProvider.autoDispose
    .family<DictionaryEntry, String>(
      (ref, id) => ref.watch(dictionaryRepositoryProvider).detail(id),
    );
