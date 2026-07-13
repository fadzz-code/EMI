import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/data/admin_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin summary flattens backend metrics without fake numbers', () {
    final summary = AdminSummary.fromJson({
      'users': {'students': 10, 'teachers': 2},
      'classes': 3,
    });

    expect(summary.items.map((item) => item.label), contains('users students'));
    expect(summary.items.map((item) => item.value), contains('10'));
  });

  test('admin query keeps stable provider identity', () {
    const a = AdminFeatureQuery(
      feature: AdminFeature.users,
      query: AdminListQuery(search: 'emi'),
    );
    const b = AdminFeatureQuery(
      feature: AdminFeature.users,
      query: AdminListQuery(search: 'emi'),
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('repository uses real admin and shared endpoints', () async {
    final requests = <String>[];
    final repository = AdminRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              if (options.path == '/admin/dashboard/summary') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': {
                        'users': {'students': 1},
                      },
                    },
                  ),
                );
                return;
              }
              if (options.path == '/users') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': [
                        {'id': 'u1', 'full_name': 'Admin', 'email': 'a@test'},
                      ],
                      'meta': {'current_page': 1, 'last_page': 1},
                    },
                  ),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        ),
      const DioErrorMapper(),
    );

    expect((await repository.dashboard()).items.single.value, '1');
    expect(
      (await repository.list(
        '/users',
        const AdminListQuery(),
      )).items.single.title,
      'Admin',
    );
    expect(requests, contains('GET /admin/dashboard/summary'));
    expect(requests, contains('GET /users'));
  });
}
