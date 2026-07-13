import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'culture_models.dart';
import 'culture_repository.dart';

final cultureRepositoryProvider = Provider<CultureRepository>(
  (ref) => CultureRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final cultureListProvider = FutureProvider.autoDispose
    .family<CulturePage, CultureQuery>((ref, query) {
      return ref
          .watch(cultureRepositoryProvider)
          .list(page: query.page, perPage: query.perPage);
    });
