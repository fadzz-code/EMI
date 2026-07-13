import 'package:emi_mobile/features/profile/presentation/avatar_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = AvatarValidator();

  test('accepts backend avatar image types within size limit', () {
    for (final fileName in [
      'avatar.jpg',
      'avatar.jpeg',
      'avatar.png',
      'avatar.webp',
    ]) {
      expect(
        validator
            .validate(fileName: fileName, sizeBytes: AvatarValidator.maxBytes)
            .isValid,
        isTrue,
      );
    }
  });

  test('rejects invalid avatar MIME by extension', () {
    final result = validator.validate(fileName: 'avatar.gif', sizeBytes: 100);

    expect(result.isValid, isFalse);
    expect(result.message, 'Format avatar harus JPG, PNG, atau WebP.');
  });

  test('rejects avatar over backend size limit', () {
    final result = validator.validate(
      fileName: 'avatar.png',
      sizeBytes: AvatarValidator.maxBytes + 1,
    );

    expect(result.isValid, isFalse);
    expect(result.message, 'Ukuran avatar maksimal 5 MB.');
  });
}
