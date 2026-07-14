import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/data/admin_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_repository.dart';
import 'package:emi_mobile/features/admin/presentation/admin_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  testWidgets('admin class movement updates target and source detail caches', (
    tester,
  ) async {
    final requests = <String>[];
    final repository = AdminRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              if (options.path == '/classes/c2') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': {
                        'id': 'c2',
                        'name': 'Kelas Baru',
                        'status': 'active',
                        'active_students_count': 0,
                      },
                    },
                  ),
                );
                return;
              }
              if (options.path == '/classes/c2/students') {
                handler.resolve(
                  Response(requestOptions: options, data: {'data': []}),
                );
                return;
              }
              if (options.path == '/users') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': [
                        {
                          'id': 'u1',
                          'full_name': 'Siswa A',
                          'email': 'a@test',
                          'role': 'student',
                          'status': 'approved',
                          'active_class': {'id': 'c1', 'name': 'Kelas Lama'},
                        },
                      ],
                    },
                  ),
                );
                return;
              }
              if (options.path == '/classes/c2/assign-student') {
                handler.resolve(
                  Response(requestOptions: options, data: {'data': {}}),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        ),
      const DioErrorMapper(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/admin/classes/c2',
            routes: [
              GoRoute(
                path: '/admin/classes/:id',
                builder: (_, state) =>
                    AdminClassDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final addBtn = find.text('Tambah Siswa');
    await tester.dragUntilVisible(
      addBtn,
      find.byType(Scrollable),
      const Offset(0, -500),
    );
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    expect(find.text('Siswa A'), findsOneWidget);
    await tester.tap(find.text('Siswa A'));
    await tester.pumpAndSettle();

    expect(find.text('Pindahkan Siswa?'), findsOneWidget);
    await tester.tap(find.text('Pindahkan'));
    await tester.pumpAndSettle();

    expect(requests, contains('POST /classes/c2/assign-student'));
    expect(tester.takeException(), isNull);
  });
}
