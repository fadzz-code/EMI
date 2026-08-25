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
  test('menu settings keeps endpoint and route', () {
    expect(AdminFeature.settings.label, 'Pengaturan');
    expect(AdminFeature.settings.endpoint, '/admin/settings');
    expect(AdminFeature.settings.route, '/admin/settings');
    expect(AdminFeature.settings.isMobileImplemented, isTrue);
  });

  test('admin settings parses banner and activity logs only', () async {
    final requests = <String>[];
    final settings = await _repository(requests: requests).get();

    expect(settings.banner.enabled, isTrue);
    expect(settings.activityLogs.single.title, 'Banner login diperbarui');
    expect(requests, ['GET /admin/settings']);
  });

  test('admin settings invalid object maps to app error', () {
    expect(_repository(invalid: true).get(), throwsA(isA<AppError>()));
  });

  testWidgets('shows professional final sections and no removed settings', (
    tester,
  ) async {
    final completer = Completer<void>();
    await _pump(tester, repository: _repository(wait: completer.future));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete();
    await tester.pumpAndSettle();

    for (final text in [
      'Profil Admin',
      'Banner Login',
      'Banner tampil pada halaman login desktop. Gunakan gambar JPG, JPEG, atau PNG maksimal 5 MB.',
      'Ubah Password',
      'Aktivitas terbaru',
      'Banner login diperbarui',
    ]) {
      await _findByScrolling(tester, text);
    }
    expect(find.text('Pengaturan Aplikasi'), findsNothing);
    expect(find.text('Keamanan'), findsNothing);
    expect(find.byKey(const Key('saveApplicationSettings')), findsNothing);
    expect(find.byKey(const Key('saveSecuritySettings')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dirty protection tracks profile banner and password only', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama Lengkap'),
      'Admin Baru',
    );
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Batalkan perubahan?'), findsOneWidget);
    await tester.tap(find.text('Tetap di Halaman'));
    await tester.pumpAndSettle();

    await _findByScrolling(tester, 'Aktifkan Banner');
    await tester.tap(find.text('Aktifkan Banner'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('saveBannerSettings')))
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  AdminSettingsRepository? repository,
}) async {
  final auth = _MockAuthRepository();
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
        authRepositoryProvider.overrideWithValue(auth),
        authControllerProvider.overrideWith((_) => _AuthNotifier(auth)),
      ],
      child: MaterialApp.router(theme: EmiTheme.light(), routerConfig: router),
    ),
  );
}

Future<void> _findByScrolling(WidgetTester tester, String text) async {
  final list = find
      .descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(find.text(text).first, 300, scrollable: list);
  await tester.pump();
}

AdminSettingsRepository _repository({
  List<String>? requests,
  Future<void>? wait,
  bool invalid = false,
}) => AdminSettingsRepository(
  Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests?.add('${options.method} ${options.path}');
          if (wait != null) await wait;
          handler.resolve(
            Response(
              requestOptions: options,
              data: invalid ? const {'data': []} : _response(options),
            ),
          );
        },
      ),
    ),
  const DioErrorMapper(),
);

Map<String, dynamic> _response(RequestOptions options) {
  if (options.method != 'GET') {
    return {'data': Map<String, dynamic>.from(options.data as Map)};
  }
  return {
    'data': {
      'application': {'name': 'diabaikan'},
      'banner': {'enabled': true, 'image_url': null},
      'security': {'new_login_alert': true},
      'activity_logs': [
        {
          'id': 'log-1',
          'admin': 'Admin EMI',
          'title': 'Banner login diperbarui',
          'status': true,
          'created_at': '2026-07-16T10:00:00Z',
        },
      ],
    },
  };
}
