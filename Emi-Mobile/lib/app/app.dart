import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/network_status_controller.dart';
import '../features/modules/presentation/student_module_offline_providers.dart';
import 'router/app_router.dart';
import 'theme/emi_theme.dart';

class EmiMobileApp extends ConsumerWidget {
  const EmiMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.watch(networkStatusControllerProvider);
    ref.watch(moduleSyncCoordinatorProvider);

    return MaterialApp.router(
      title: 'EMI Mobile',
      debugShowCheckedModeBanner: false,
      theme: EmiTheme.light(),
      routerConfig: router,
    );
  }
}
