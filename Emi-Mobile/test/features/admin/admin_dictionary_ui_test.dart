import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:emi_mobile/app/theme/emi_theme.dart';
import 'package:emi_mobile/features/admin/presentation/admin_dictionary_screens.dart';
import 'package:emi_mobile/features/admin/data/admin_crud_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_crud_repository.dart';

void main() {
  testWidgets(
    'admin dictionary UI is a single scroll view containing header and list without nested list view',
    (tester) async {
      final mockEntries = [
        const DictionaryEntryAdmin(
          id: '1',
          mekongga: 'Air',
          indonesia: 'Air',
          english: 'Water',
          categoryId: 'c1',
        ),
        const DictionaryEntryAdmin(
          id: '2',
          mekongga: 'mekambo',
          indonesia: 'jatuh',
          english: 'fall',
          categoryId: 'c2',
        ),
      ];

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const AdminDictionaryScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminDictionaryProvider(
              const AdminSearchQuery(page: 1),
            ).overrideWith((_) => AdminCrudPage(items: mockEntries, total: 2)),
            dictionaryCategoriesProvider.overrideWith(
              (_) => const AdminCrudPage(items: []),
            ),
          ],
          child: MaterialApp.router(
            theme: EmiTheme.light(),
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final customScrollFinder = find.byType(CustomScrollView);
      expect(
        customScrollFinder,
        findsOneWidget,
        reason: 'Must use a single CustomScrollView for whole page',
      );

      final introFinder = find.text(
        'Kelola kosakata Mekongga agar mudah dipelajari siswa.',
      );
      expect(introFinder, findsOneWidget);
      expect(
        find.descendant(of: customScrollFinder, matching: introFinder),
        findsOneWidget,
      );

      final searchFinder = find.byIcon(Icons.search);
      expect(searchFinder, findsOneWidget);
      expect(
        find.descendant(of: customScrollFinder, matching: searchFinder),
        findsOneWidget,
      );

      final addBtnFinder = find.text('Tambah Kosakata');
      expect(addBtnFinder, findsOneWidget);
      expect(
        find.descendant(of: customScrollFinder, matching: addBtnFinder),
        findsOneWidget,
      );

      final itemFinder = find.text('Air');
      expect(itemFinder, findsWidgets);
      expect(
        find.descendant(of: customScrollFinder, matching: itemFinder),
        findsWidgets,
      );

      final listViewFinder = find.byType(ListView);
      expect(
        listViewFinder,
        findsNothing,
        reason: 'Avoid using nested ListView inside CustomScrollView',
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('admin dictionary UI audio form displays correct state', (
    tester,
  ) async {
    const mockEntry = DictionaryEntryAdmin(
      id: '1',
      mekongga: 'Air',
      indonesia: 'Air',
      english: 'Water',
      categoryId: 'c1',
      audioUrl: 'https://example.com/audio.mp3',
    );

    final router = GoRouter(
      initialLocation: '/admin/dictionary/1/edit',
      routes: [
        GoRoute(
          path: '/admin/dictionary/:id/edit',
          builder: (context, state) =>
              AdminDictionaryFormScreen(id: state.pathParameters['id']),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDictionaryDetailProvider('1').overrideWith((_) => mockEntry),
          dictionaryCategoriesProvider.overrideWith(
            (_) => const AdminCrudPage(items: []),
          ),
        ],
        child: MaterialApp.router(
          theme: EmiTheme.light(),
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final titleFinder = find.text('Edit Kosakata');
    expect(titleFinder, findsWidgets);

    final audioSection = find.text('Audio Pelafalan');
    await tester.scrollUntilVisible(
      audioSection,
      50,
      scrollable: find.byType(Scrollable).first,
    );
    expect(audioSection, findsOneWidget);

    expect(find.text('Audio tersedia'), findsOneWidget);
    expect(find.text('Ganti Audio'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    final hapusBtn = find.text('Hapus Audio');
    expect(hapusBtn, findsOneWidget);

    await tester.tap(hapusBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    final batalHapus = find.text('Batal Hapus');
    expect(find.text('Audio akan dihapus setelah disimpan.'), findsOneWidget);
    expect(batalHapus, findsOneWidget);

    await tester.tap(batalHapus, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Audio tersedia'), findsOneWidget);
    expect(find.text('Hapus Audio'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
