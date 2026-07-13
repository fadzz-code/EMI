class AvatarValidationResult {
  const AvatarValidationResult._(this.message);

  const AvatarValidationResult.valid() : this._(null);
  const AvatarValidationResult.invalid(String message) : this._(message);

  final String? message;
  bool get isValid => message == null;
}

class AvatarValidator {
  const AvatarValidator();

  static const maxBytes = 5120 * 1024;
  static const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  AvatarValidationResult validate({
    required String fileName,
    required int sizeBytes,
  }) {
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return const AvatarValidationResult.invalid(
        'Format avatar harus JPG, PNG, atau WebP.',
      );
    }
    if (sizeBytes > maxBytes) {
      return const AvatarValidationResult.invalid(
        'Ukuran avatar maksimal 5 MB.',
      );
    }
    return const AvatarValidationResult.valid();
  }
}
