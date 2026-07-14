import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/data/admin_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin settings parses object response and nullable values', () async {
    final requests = <String>[];
    final repository = AdminSettingsRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'data': {
                      'application': {
                        'name': 'EMI',
                        'subtitle': null,
                        'active_academic_year': '2026/2027',
                        'timezone': 'Asia/Makassar',
                      },
                      'banner': {'enabled': 1, 'image_url': null},
                      'security': {
                        'new_login_alert': false,
                        'weekly_report_email': '1',
                      },
                      'activity_logs': [
                        {
                          'id': 'log-1',
                          'admin': 'Admin',
                          'title': 'Update',
                          'status': true,
                        },
                      ],
                    },
                  },
                ),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );

    final settings = await repository.get();

    expect(settings.application.name, 'EMI');
    expect(settings.application.subtitle, '');
    expect(settings.banner.enabled, isTrue);
    expect(settings.security.weeklyReportEmail, isTrue);
    expect(settings.activityLogs.single.title, 'Update');
    expect(requests, ['GET /admin/settings']);
  });

  test('admin settings update uses backend contracts', () async {
    final requests = <String>[];
    final bodies = <Map<String, dynamic>>[];
    final repository = AdminSettingsRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              bodies.add(Map<String, dynamic>.from(options.data as Map));
              handler.resolve(
                Response(requestOptions: options, data: {'data': options.data}),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );

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
    expect(bodies.first['active_academic_year'], '2026/2027');
    expect(bodies.last['new_login_alert'], isTrue);
  });

  test('admin settings invalid object maps to app error', () async {
    final repository = AdminSettingsRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.resolve(
              Response(requestOptions: options, data: {'data': []}),
            ),
          ),
        ),
      const DioErrorMapper(),
    );

    expect(repository.get(), throwsA(isA<AppError>()));
  });
}
