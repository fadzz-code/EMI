import 'package:emi_mobile/features/admin/presentation/admin_shell.dart';
import 'package:emi_mobile/shared/widgets/emi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<GoRouter> pumpShell(WidgetTester tester, String location) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        for (final route in [
          '/admin/dashboard',
          '/admin/approvals',
          '/admin/schools',
          '/admin/classes',
          '/admin/users',
          '/admin/dictionary',
          '/admin/reports',
          '/admin/settings',
        ])
          GoRoute(
            path: route,
            builder: (_, _) =>
                const AdminShell(title: 'Admin', child: SizedBox()),
          ),
        GoRoute(
          path: '/admin/reports/students/:id',
          builder: (_, _) => const AdminShell(
            title: 'Detail Progress',
            fallbackRoute: '/admin/reports',
            child: SizedBox(),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('drawer admin follows web order and groups school routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpShell(tester, '/admin/dashboard');
    await tester.tap(find.byKey(const Key('adminMenuButton')));
    await tester.pumpAndSettle();

    final labels = [
      'Beranda',
      'Persetujuan',
      'Sekolah & Kelas',
      'Guru & Siswa',
      'Kamus',
      'Basis AI',
      'Modul',
      'Kuis',
      'Template Speaking',
      'Budaya Mekongga',
      'Progress',
      'Pengaturan',
    ];
    final drawer = find.byType(Drawer);
    for (var index = 1; index < labels.length; index++) {
      expect(
        tester
            .getTopLeft(
              find
                  .descendant(
                    of: drawer,
                    matching: find.text(labels[index - 1]),
                  )
                  .first,
            )
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find
                    .descendant(of: drawer, matching: find.text(labels[index]))
                    .first,
              )
              .dy,
        ),
      );
    }
    expect(
      find.descendant(of: drawer, matching: find.text('Sekolah')),
      findsNothing,
    );
    expect(
      find.descendant(of: drawer, matching: find.text('Pengguna')),
      findsNothing,
    );
    await tester.tap(
      find.descendant(of: drawer, matching: find.text('Sekolah & Kelas')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sekolah'), findsOneWidget);
    expect(find.text('Kelas & Penempatan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening admin roots keeps selected ListTile on Material', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = await pumpShell(tester, '/admin/dashboard');

    for (final route in [
      '/admin/dashboard',
      '/admin/approvals',
      '/admin/schools',
      '/admin/classes',
      '/admin/users',
      '/admin/dictionary',
      '/admin/reports',
      '/admin/settings',
    ]) {
      router.go(route);
      await tester.pumpAndSettle();
      final domain = route.split('/').last;
      expect(find.byKey(Key('adminScreen-$domain')), findsOneWidget);
      expect(find.byKey(Key('adminTitle-$domain')), findsOneWidget);
      await tester.tap(find.byKey(const Key('adminMenuButton')));
      await tester.pumpAndSettle();
      final selectedTile = tester.widget<ListTile>(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.byWidgetPredicate(
            (widget) => widget is ListTile && widget.selected,
          ),
        ),
      );
      expect(selectedTile.selectedTileColor, isNotNull);
      expect(
        find.ancestor(
          of: find.byWidget(selectedTile),
          matching: find.byType(Material),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(Drawer))).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('admin card routes provide Material to ListTile variants', (
    tester,
  ) async {
    const routes = <String, Widget>{
      '/admin/approvals': ListTile(title: Text('Approval')),
      '/admin/users': ListTile(title: Text('User')),
      '/admin/schools': ListTile(title: Text('School')),
      '/admin/classes': ListTile(title: Text('Class')),
      '/admin/reports': ListTile(title: Text('Report')),
      '/admin/settings': SwitchListTile(value: true, onChanged: null),
    };

    for (final entry in routes.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmiCard(key: ValueKey(entry.key), child: entry.value),
          ),
        ),
      );
      await tester.pump();
      final tile = find.descendant(
        of: find.byKey(ValueKey(entry.key)),
        matching: find.byType(entry.value.runtimeType),
      );
      expect(
        find.ancestor(of: tile, matching: find.byType(Material)),
        findsWidgets,
        reason: entry.key,
      );
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  testWidgets('quick navigation has four balanced root actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = await pumpShell(tester, '/admin/dictionary');

    expect(find.byType(AdminQuickNavigation), findsOneWidget);
    for (final label in ['Beranda', 'Persetujuan', 'Progress', 'Pengaturan']) {
      expect(
        find.descendant(
          of: find.byType(AdminQuickNavigation),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    for (final key in [
      'adminQuickHome',
      'adminQuickApprovals',
      'adminQuickProgress',
      'adminQuickSettings',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(
      find.byKey(const Key('adminQuickHome')).evaluate().single.widget,
      isA<InkWell>(),
    );

    await tester.tap(find.byKey(const Key('adminQuickProgress')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/admin/reports');
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct detail system back falls back to progress', (
    tester,
  ) async {
    final router = await pumpShell(tester, '/admin/reports/students/1');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/admin/reports');
    expect(tester.takeException(), isNull);
  });
}
