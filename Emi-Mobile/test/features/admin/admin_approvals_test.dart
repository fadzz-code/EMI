import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emi_mobile/features/admin/presentation/admin_approvals_screens.dart';
import 'package:emi_mobile/features/admin/data/admin_crud_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_crud_repository.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
import 'package:emi_mobile/features/auth/presentation/auth_state.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthController {
  _FakeAuthNotifier()
    : super(
        const AuthState(
          status: AuthStatus.authenticatedAdmin,
          user: SessionUser(
            id: 'admin-1',
            email: 'admin@test',
            fullName: 'Admin',
            role: UserRole.admin,
            status: 'approved',
          ),
        ),
      );

  @override
  Future<void> login({required String email, required String password}) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> updateProfile({required String fullName, String? phone}) async {}
  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {}
  @override
  Future<void> uploadAvatar({
    required String path,
    required String fileName,
    void Function(int sent, int total)? onSendProgress,
  }) async {}
  @override
  Future<void> deleteAvatar() async {}
  @override
  Future<void> deleteAccount({required String currentPassword}) async {}
  @override
  void invalidateSession() {}
  @override
  Future<void> restoreSession() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('admin approval shows conflict dialog for assigned teacher', (
    tester,
  ) async {
    final repository = AdminCrudRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path == '/admin/registration-requests/req-1') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': {
                        'id': 'req-1',
                        'requested_role': 'teacher',
                        'status': 'pending',
                        'user': {'full_name': 'Guru', 'email': 'g@test'},
                        'school': {'name': 'SMP'},
                        'school_class': {'id': 'class-1', 'name': 'Kelas 7A'},
                      },
                    },
                  ),
                );
                return;
              }
              if (options.path ==
                  '/admin/registration-requests/req-1/approve') {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 409,
                      data: {
                        'success': false,
                        'code': 'CLASS_ALREADY_HAS_TEACHER',
                        'message': 'Kelas sudah memiliki guru aktif.',
                        'errors': [],
                      },
                    ),
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminCrudRepositoryProvider.overrideWithValue(repository),
          authControllerProvider.overrideWith((ref) => _FakeAuthNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/admin/approvals/req-1',
            routes: [
              GoRoute(
                path: '/admin/approvals/:id',
                builder: (_, state) =>
                    AdminApprovalDetailScreen(id: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '/admin/classes/:id',
                builder: (_, state) =>
                    Text('Class Detail ${state.pathParameters['id']}'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminApprovalDetailScreen')), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adminApprovalApprove')), findsOneWidget);
    expect(find.byKey(const Key('adminApprovalReject')), findsOneWidget);
    await tester.tap(find.byKey(const Key('adminApprovalApprove')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setujui'));
    await tester.pumpAndSettle();

    // Verify conflict dialog
    expect(find.text('Akun Belum Bisa Disetujui'), findsOneWidget);
    expect(
      find.textContaining('Kelas yang dipilih sudah memiliki Guru aktif'),
      findsOneWidget,
    );
    expect(find.textContaining('CLASS_ALREADY_HAS_TEACHER'), findsNothing);

    // Verify detail screen is still there and status is pending
    expect(find.text('Menunggu Persetujuan'), findsOneWidget);

    // Verify 'Buka Kelas' button opens class detail
    await tester.tap(find.text('Buka Kelas'));
    await tester.pumpAndSettle();
    expect(find.text('Class Detail class-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
