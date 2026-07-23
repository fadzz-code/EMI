class E2eConfig {
  const E2eConfig._();

  static const adminEmail = String.fromEnvironment('E2E_ADMIN_EMAIL');
  static const adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD');
  static const teacherEmail = String.fromEnvironment('E2E_TEACHER_EMAIL');
  static const teacherPassword = String.fromEnvironment('E2E_TEACHER_PASSWORD');
  static const studentEmail = String.fromEnvironment('E2E_STUDENT_EMAIL');
  static const studentPassword = String.fromEnvironment('E2E_STUDENT_PASSWORD');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static void validate() {
    const values = {
      'E2E_ADMIN_EMAIL': adminEmail,
      'E2E_ADMIN_PASSWORD': adminPassword,
      'E2E_TEACHER_EMAIL': teacherEmail,
      'E2E_TEACHER_PASSWORD': teacherPassword,
      'E2E_STUDENT_EMAIL': studentEmail,
      'E2E_STUDENT_PASSWORD': studentPassword,
      'API_BASE_URL': apiBaseUrl,
    };
    final missing = values.entries
        .where((entry) => entry.value.trim().isEmpty)
        .map((entry) => entry.key)
        .join(', ');
    if (missing.isNotEmpty) {
      throw StateError('Dart define E2E wajib kosong/tidak tersedia: $missing');
    }
  }
}
