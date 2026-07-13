import 'package:emi_mobile/app/app.dart';
import 'package:emi_mobile/features/auth/data/auth_providers.dart';
import 'package:emi_mobile/features/auth/domain/auth_repository.dart';
import 'package:emi_mobile/features/auth/domain/session_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<SessionUser> currentUser() async => throw UnimplementedError();

  @override
  Future<SessionUser> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<SessionUser?> restoreSession() async => null;
}

void main() {
  testWidgets('app starts at login after empty session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const EmiMobileApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Masuk EMI'), findsOneWidget);
  });
}
