import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emi_mobile/app/theme/emi_theme.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/data/admin_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_settings_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_settings_repository.dart';
import 'package:emi_mobile/features/admin/presentation/admin_settings_screen.dart';
import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _AuthNotifier extends AuthController {
  _AuthNotifier(super.repository) {
    state = const AuthState(status: AuthStatus.authenticatedAdmin, user: _user);
  }
}

const _user = SessionUser(
  id: 'admin-1',
  fullName: 'Admin EMI',
  email: 'admin@emi.test',
  phone: '081234',
  role: UserRole.admin,
  status: 'approved',
);

void main() {
  test('menu settings keeps actual label endpoint and route', () {
    expect(AdminFeature.settings.label, 'Pengaturan');
    expect(AdminFeature.settings.endpoint, '/admin/settings');
    expect(AdminFeature.settings.route, '/admin/settings');
    expect(AdminFeature.settings.isMobileImplemented, isTrue);
  });

  test('admin settings parses object response and nullable values', () async {
    final requests = <String>[];
    final repository = _repository(requests: requests);

    final settings = await repository.get();

    expect(settings.application.name, 'EMI');
    expect(settings.application.subtitle, 'Belajar bersama');
    expect(settings.application.activeAcademicYear, '2026/2027');
    expect(settings.application.timezone, 'Asia/Makassar');
    expect(settings.banner.enabled, isTrue);
    expect(settings.security.weeklyReportEmail, isTrue);
    expect(settings.activityLogs.single.title, 'Update pengaturan');
    expect(requests, ['GET /admin/settings']);
  });

  test('admin settings update uses backend contracts', () async {
    final requests = <String>[];
    final repository = _repository(requests: requests);

    await repository.updateApplication(
      const ApplicationSettings(
        name: 'EMI',
        subtitle: 'Belajar',
        activeAcademicYear: '2026/2027',
        timezone: 'Asia/Makassar',
      ),
    );
    await repository.updateSecurity(
      const SecuritySettings(newLoginAlert: true, weeklyReportEmail: false),
    );

    expect(requests, [
      'PUT /admin/settings/application',
      'PUT /admin/settings/security',
    ]);
  });

  test('admin settings invalid object maps to app error', () async {
    final repository = _repository(invalid: true);
    expect(repository.get(), throwsA(isA<AppError>()));
  });

  testWidgets(
    'shows loading then all typed sections fields and pristine save',
    (tester) async {
      final completer = Completer<void>();
      await _pump(tester, repository: _repository(wait: completer.future));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete();
      await tester.pumpAndSettle();

      for (final text in [
        'Pengaturan Aplikasi',
        'Profil Admin',
        'Nama Aplikasi',
        'Subtitle / Slogan',
        'Tahun Ajaran Aktif',
        'Zona Waktu',
        'Nama Lengkap',
        'Telepon Admin',
        'Email Kantor',
        'Status Akun',
      ]) {
        await _findByScrolling(tester, text);
      }
      for (final text in [
        'Pengaturan Banner Login',
        'Keamanan',
        'Ubah Password',
        'Aktivitas',
        'Peringatan Login Baru',
        'Email Laporan Mingguan',
        'Update pengaturan',
        'Simpan Pengaturan',
      ]) {
        await _findByScrolling(tester, text);
      }
      expect(find.text('application.name'), findsNothing);
      expect(find.text('new_login_alert'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('saveAdminSettings')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('error maps friendly and retry reloads settings', (tester) async {
    final requests = <String>[];
    await _pump(
      tester,
      repository: _repository(requests: requests, failures: 1),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coba lagi'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan Aplikasi'), findsOneWidget);
    expect(
      requests.where((request) => request == 'GET /admin/settings'),
      hasLength(2),
    );
  });

  testWidgets('switches and timezone selection create dirty state', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    await _findByScrolling(tester, 'Zona Waktu');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asia/Jayapura').last);
    await _findByScrolling(tester, 'Aktifkan Banner');
    await tester.tap(find.text('Aktifkan Banner'));
    await _findByScrolling(tester, 'Peringatan Login Baru');
    await tester.tap(find.text('Peringatan Login Baru'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Aktifkan Banner'),
          )
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Peringatan Login Baru'),
          )
          .value,
      isTrue,
    );
    expect(find.text('Asia/Jayapura'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('saveAdminSettings')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'validates required and password fields without exposing secret',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      final name = find.widgetWithText(TextFormField, 'Nama Aplikasi');
      await tester.enterText(name, '');
      await _findByScrolling(tester, 'Password Lama');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password Lama'),
        'old-secret',
      );
      tester
          .widget<FilledButton>(find.byKey(const Key('saveAdminSettings')))
          .onPressed!();
      await tester.pump();

      expect(find.text('Wajib diisi.'), findsOneWidget);
      expect(find.widgetWithText(Text, 'old-secret'), findsNothing);
      expect(find.text('Lengkapi semua kolom password.'), findsNothing);
      for (final label in [
        'Password Lama',
        'Password Baru',
        'Konfirmasi Password Baru',
      ]) {
        final field = find.widgetWithText(TextFormField, label);
        expect(
          tester
              .widget<EditableText>(
                find.descendant(of: field, matching: find.byType(EditableText)),
              )
              .obscureText,
          isTrue,
        );
      }
    },
  );

  testWidgets('save success updates baseline and sends no blank password', (
    tester,
  ) async {
    final requests = <String>[];
    final auth = _MockAuthRepository();
    await _pump(
      tester,
      repository: _repository(requests: requests),
      auth: auth,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama Aplikasi'),
      'EMI Baru',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('saveAdminSettings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveAdminSettings')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan berhasil disimpan.'), findsOneWidget);
    expect(requests, contains('PUT /admin/settings/application'));
    verifyNever(
      () => auth.updatePassword(
        currentPassword: any(named: 'currentPassword'),
        password: any(named: 'password'),
        passwordConfirmation: any(named: 'passwordConfirmation'),
      ),
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('saveAdminSettings')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('save failure retains input and stays dirty', (tester) async {
    await _pump(tester, repository: _repository(failUpdates: true));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama Aplikasi'),
      'Tetap Ada',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('saveAdminSettings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveAdminSettings')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Nama Aplikasi'),
          )
          .controller!
          .text,
      'Tetap Ada',
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();
    expect(find.text('Permintaan API gagal.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('saveAdminSettings')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('system and app bar back show exact dirty confirmation', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama Aplikasi'),
      'Kotor',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    _expectConfirmation();
    await tester.tap(find.text('Tetap di Halaman'));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan').last, findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    _expectConfirmation();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('keyboard scroll reaches save and text scale has no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, textScale: 1.2);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextFormField, 'Nama Aplikasi'));
    await tester.showKeyboard(
      find.widgetWithText(TextFormField, 'Nama Aplikasi'),
    );
    await _findByScrolling(tester, 'Simpan Pengaturan');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saveAdminSettings')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _expectConfirmation() {
  expect(find.text('Batalkan perubahan?'), findsOneWidget);
  expect(
    find.text('Perubahan yang belum disimpan akan hilang.'),
    findsOneWidget,
  );
  expect(find.text('Tetap di Halaman'), findsOneWidget);
  expect(find.text('Keluar'), findsOneWidget);
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  AdminSettingsRepository? repository,
  AuthRepository? auth,
  double textScale = 1,
}) async {
  final router = GoRouter(
    initialLocation: '/admin/settings',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Beranda')),
        routes: [
          GoRoute(
            path: 'admin/settings',
            builder: (_, _) => const AdminSettingsScreen(),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminSettingsRepositoryProvider.overrideWithValue(
          repository ?? _repository(),
        ),
        authRepositoryProvider.overrideWithValue(auth ?? _MockAuthRepository()),
        authControllerProvider.overrideWith(
          (_) => _AuthNotifier(auth ?? _MockAuthRepository()),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp.router(
          theme: EmiTheme.light(),
          routerConfig: router,
        ),
      ),
    ),
  );
  return router;
}

Future<void> _findByScrolling(WidgetTester tester, String text) async {
  final list = find
      .descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(find.text(text), 300, scrollable: list);
  await tester.pump();
}

AdminSettingsRepository _repository({
  List<String>? requests,
  Future<void>? wait,
  int failures = 0,
  bool failUpdates = false,
  bool invalid = false,
}) {
  var remainingFailures = failures;
  return AdminSettingsRepository(
    Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            requests?.add('${options.method} ${options.path}');
            if (wait != null) await wait;
            if (remainingFailures > 0 ||
                (failUpdates && options.method != 'GET')) {
              if (remainingFailures > 0) remainingFailures--;
              handler.reject(DioException(requestOptions: options));
              return;
            }
            if (invalid) {
              handler.resolve(
                Response(requestOptions: options, data: {'data': []}),
              );
              return;
            }
            handler.resolve(
              Response(requestOptions: options, data: _response(options)),
            );
          },
        ),
      ),
    const DioErrorMapper(),
  );
}

Map<String, dynamic> _response(RequestOptions options) {
  if (options.method != 'GET') {
    return {'data': Map<String, dynamic>.from(options.data as Map)};
  }
  return {
    'data': {
      'application': {
        'name': 'EMI',
        'subtitle': 'Belajar bersama',
        'active_academic_year': '2026/2027',
        'timezone': 'Asia/Makassar',
      },
      'banner': {'enabled': true, 'image_url': null},
      'security': {'new_login_alert': false, 'weekly_report_email': true},
      'activity_logs': [
        {
          'id': 'log-1',
          'admin': 'Admin EMI',
          'title': 'Update pengaturan',
          'status': true,
          'created_at': '2026-07-16T10:00:00Z',
        },
      ],
    },
  };
}
