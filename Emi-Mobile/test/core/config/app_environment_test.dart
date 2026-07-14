import 'package:emi_mobile/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps physical device development base URL', () {
    final env = AppEnvironment.fromDefines(
      appEnv: 'development',
      apiBaseUrl: 'http://127.0.0.1:8000/api/v1',
    );

    expect(env.apiBaseUrl, 'http://127.0.0.1:8000/api/v1');
  });

  test('keeps Android emulator development base URL', () {
    final env = AppEnvironment.fromDefines(
      appEnv: 'development',
      apiBaseUrl: 'http://10.0.2.2:8000/api/v1',
    );

    expect(env.apiBaseUrl, 'http://10.0.2.2:8000/api/v1');
  });

  test('production requires HTTPS', () {
    expect(
      () => AppEnvironment.fromDefines(
        appEnv: 'production',
        apiBaseUrl: 'http://example.test',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
