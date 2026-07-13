class LoginValidator {
  const LoginValidator();

  String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi.';
    if (!text.contains('@')) return 'Format email belum valid.';
    return null;
  }

  String? password(String? value) {
    if ((value ?? '').isEmpty) return 'Password wajib diisi.';
    return null;
  }
}
