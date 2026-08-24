import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:emi_mobile/app/theme/emi_theme.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/presentation/admin_dictionary_screens.dart';
import 'package:emi_mobile/features/admin/presentation/admin_knowledge_screens.dart';
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
      await tester.drag(customScrollFinder, const Offset(0, -400));
      await tester.pumpAndSettle();
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

  testWidgets('admin dictionary detail hides media ID and formats dates', (
    tester,
  ) async {
    const entry = DictionaryEntryAdmin(
      id: '1',
      mekongga: 'Air',
      indonesia: 'Air',
      english: 'Water',
      categoryId: 'c1',
      audioMediaId: 'raw-media-id',
      createdAt: '2026-07-15T00:00:00Z',
      updatedAt: '2026-07-16T00:00:00Z',
    );
    final router = GoRouter(
      initialLocation: '/admin/dictionary/1',
      routes: [
        GoRoute(
          path: '/admin/dictionary/:id',
          builder: (_, state) =>
              AdminDictionaryDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDictionaryDetailProvider('1').overrideWith((_) => entry),
        ],
        child: MaterialApp.router(
          theme: EmiTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('raw-media-id'), findsNothing);
    expect(find.text('Dibuat: 15/07/2026'), findsOneWidget);
    expect(find.text('Terakhir Diubah: 16/07/2026'), findsOneWidget);
  });

  testWidgets(
    'failed detail delete stays, reports error, and blocks double tap',
    (tester) async {
      var deletes = 0;
      final deleteResult = Completer<void>();
      final repository = AdminCrudRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) async {
                if (options.method == 'DELETE') {
                  deletes++;
                  await deleteResult.future;
                  handler.reject(
                    DioException.connectionError(
                      requestOptions: options,
                      reason: 'offline',
                    ),
                  );
                }
              },
            ),
          ),
        const DioErrorMapper(),
      );
      const entry = DictionaryEntryAdmin(
        id: '1',
        mekongga: 'Mowali',
        indonesia: 'Pulang',
        english: 'Go home',
        categoryId: 'c1',
      );
      final router = GoRouter(
        initialLocation: '/admin/dictionary/1',
        routes: [
          GoRoute(
            path: '/admin/dictionary/:id',
            builder: (_, state) =>
                AdminDictionaryDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/dictionary',
            builder: (_, _) => const SizedBox(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminCrudRepositoryProvider.overrideWithValue(repository),
            adminDictionaryDetailProvider('1').overrideWith((_) => entry),
          ],
          child: MaterialApp.router(
            theme: EmiTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Hapus'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('adminDelete-dictionary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('adminConfirmDelete-dictionary')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(deletes, 1);
      await tester.tap(find.byKey(const Key('adminDelete-dictionary')));
      await tester.pump();
      expect(deletes, 1);

      deleteResult.complete();
      await tester.pumpAndSettle();
      expect(find.text('Detail Kosakata'), findsOneWidget);
      expect(
        find.text('Kosakata belum dapat dihapus. Silakan coba lagi.'),
        findsOneWidget,
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
    expect(find.byKey(const Key('adminSave-dictionary')), findsOneWidget);
    expect(find.byKey(const Key('adminDelete-dictionary')), findsOneWidget);

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

  testWidgets('import error breakdown explicitly covers current page only', (
    tester,
  ) async {
    final repository = AdminCrudRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final data = options.path.endsWith('/errors')
                  ? {
                      'data': [
                        {
                          'id': 'error-1',
                          'code': 'REQUIRED',
                          'message': 'Wajib',
                        },
                        {
                          'id': 'error-2',
                          'code': 'REQUIRED',
                          'message': 'Wajib',
                        },
                      ],
                      'meta': {'current_page': 1, 'last_page': 5, 'total': 99},
                    }
                  : {
                      'data': [
                        {
                          'id': 'job-1',
                          'status': 'completed_with_errors',
                          'csv_original_name': 'kamus.xlsx',
                        },
                      ],
                      'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
                    };
              handler.resolve(Response(requestOptions: options, data: data));
            },
          ),
        ),
      const DioErrorMapper(),
    );
    final router = GoRouter(
      initialLocation: '/admin/dictionary/import',
      routes: [
        GoRoute(
          path: '/admin/dictionary/import',
          builder: (_, _) => const AdminDictionaryImportScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminCrudRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          theme: EmiTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('kamus.xlsx'),
      100,
      scrollable: scrollable,
    );
    await tester.drag(scrollable, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('kamus.xlsx').hitTestable());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ringkasan error halaman ini'),
      300,
      scrollable: scrollable,
    );

    expect(find.text('Ringkasan error halaman ini'), findsOneWidget);
    expect(find.text('REQUIRED · Field wajib belum diisi.: 2'), findsOneWidget);
    expect(find.textContaining('Ringkasan error total'), findsNothing);
  });

  testWidgets('knowledge form marker and save are present', (tester) async {
    final router = GoRouter(
      initialLocation: '/admin/knowledge/create',
      routes: [
        GoRoute(
          path: '/admin/knowledge/create',
          builder: (_, _) => const AdminKnowledgeFormScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: EmiTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('adminScreen-knowledge-form')), findsOneWidget);
    expect(find.byKey(const Key('adminSave-knowledge')), findsOneWidget);
  });

  testWidgets(
    'dictionary validation remains available after bottom save scroll',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/admin/dictionary/create',
        routes: [
          GoRoute(
            path: '/admin/dictionary/create',
            builder: (_, _) => const AdminDictionaryFormScreen(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dictionaryCategoriesProvider.overrideWith(
              (_) => const AdminCrudPage(items: [], total: 0),
            ),
          ],
          child: MaterialApp.router(
            theme: EmiTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      final save = find.byKey(const Key('adminSave-dictionary'));
      await tester.scrollUntilVisible(save, 300, scrollable: scrollable);
      await tester.drag(scrollable, const Offset(0, -100));
      await tester.pump();
      await tester.tap(save.hitTestable());
      await tester.pump();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/admin/dictionary/create',
      );

      for (final validation in const [
        ('adminField-dictionary-mekongga', 'Wajib diisi.'),
        ('adminField-dictionary-indonesia', 'Wajib diisi.'),
        ('adminField-dictionary-english', 'Wajib diisi.'),
        ('adminField-dictionary-category', 'Kategori wajib diisi.'),
      ]) {
        final field = find.byKey(Key(validation.$1));
        await tester.scrollUntilVisible(field, -300, scrollable: scrollable);
        await tester.pump();
        expect(
          tester.state<FormFieldState<String>>(field).errorText,
          validation.$2,
        );
      }
    },
  );

  testWidgets('dictionary form markers track category loading and data', (
    tester,
  ) async {
    final categories = Completer<AdminCrudPage<DictionaryCategory>>();
    final router = GoRouter(
      initialLocation: '/admin/dictionary/create',
      routes: [
        GoRoute(
          path: '/admin/dictionary/create',
          builder: (_, _) => const AdminDictionaryFormScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dictionaryCategoriesProvider.overrideWith((_) => categories.future),
        ],
        child: MaterialApp.router(
          theme: EmiTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('adminScreen-dictionary-form')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('adminLoading-dictionary-form')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('adminSave-dictionary')), findsNothing);

    categories.complete(const AdminCrudPage(items: [], total: 0));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminLoading-dictionary-form')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('adminSave-dictionary')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('adminSave-dictionary')), findsOneWidget);
  });
}
