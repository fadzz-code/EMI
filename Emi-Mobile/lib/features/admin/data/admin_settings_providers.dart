import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_settings_repository.dart';

final adminSettingsRepositoryProvider = Provider<AdminSettingsRepository>(
  (ref) =>
      AdminSettingsRepository(ref.watch(dioProvider), const DioErrorMapper()),
);

final adminSettingsProvider = FutureProvider<AdminSettings>(
  (ref) => ref.watch(adminSettingsRepositoryProvider).get(),
);
