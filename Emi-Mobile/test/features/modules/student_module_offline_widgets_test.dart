import 'package:emi_mobile/core/network/network_status_controller.dart';
import 'package:emi_mobile/features/modules/presentation/student_module_offline_widgets.dart';
import 'package:emi_mobile/features/modules/presentation/student_module_ui_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows offline and degraded banners', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            StudentConnectivityBanner(mode: NetworkMode.offline),
            StudentConnectivityBanner(mode: NetworkMode.degraded),
          ],
        ),
      ),
    );

    expect(find.textContaining('sedang offline'), findsOneWidget);
    expect(find.textContaining('tidak stabil'), findsOneWidget);
  });

  testWidgets('shows every module offline action state', (tester) async {
    Future<void> pump(ModuleOfflineState state) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModuleOfflineAction(
            state: state,
            onDownload: () {},
            onRemove: () {},
          ),
        ),
      ),
    );

    await pump(const ModuleOfflineState(ModuleOfflineStatus.download));
    expect(find.text('BELUM DIUNDUH'), findsOneWidget);
    await pump(
      const ModuleOfflineState(ModuleOfflineStatus.downloading, progress: .5),
    );
    expect(find.text('MENGUNDUH 50%'), findsOneWidget);
    await pump(const ModuleOfflineState(ModuleOfflineStatus.availableOffline));
    expect(find.text('Tersedia offline'), findsOneWidget);
    await tester.tap(find.text('Tersedia offline'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus dari Perangkat'), findsOneWidget);
    await pump(const ModuleOfflineState(ModuleOfflineStatus.updateAvailable));
    expect(find.text('Pembaruan tersedia'), findsOneWidget);
    await pump(const ModuleOfflineState(ModuleOfflineStatus.retry));
    expect(find.text('GAGAL MENGUNDUH'), findsOneWidget);
  });

  testWidgets('shows unavailable offline message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OfflineUnavailableMessage(onRetry: _noop)),
      ),
    );

    expect(find.text('Fitur ini memerlukan koneksi internet'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });
}

void _noop() {}
