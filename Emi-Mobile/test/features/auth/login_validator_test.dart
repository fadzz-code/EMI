import 'package:emi_mobile/features/auth/presentation/login_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = LoginValidator();

  test('validates email', () {
    expect(validator.email(''), 'Email wajib diisi.');
    expect(validator.email('invalid'), 'Format email belum valid.');
    expect(validator.email('siswa@example.test'), isNull);
  });

  test('validates password', () {
    expect(validator.password(''), 'Password wajib diisi.');
    expect(validator.password('secret'), isNull);
  });
}
