class AppEnvironment {
  const AppEnvironment({required this.name, required this.apiBaseUrl});

  final String name;
  final String apiBaseUrl;

  bool get isProduction => name == 'production';

  static const development = 'development';
  static const production = 'production';

  static AppEnvironment fromDefines({
    String appEnv = const String.fromEnvironment(
      'APP_ENV',
      defaultValue: development,
    ),
    String apiBaseUrl = const String.fromEnvironment('API_BASE_URL'),
  }) {
    final normalizedEnv = appEnv.trim().isEmpty ? development : appEnv.trim();
    final fallbackBaseUrl = normalizedEnv == production
        ? 'https://api.emi-kolaka.id'
        : 'http://10.0.2.2:8000';
    final baseUrl = apiBaseUrl.trim().isEmpty
        ? fallbackBaseUrl
        : apiBaseUrl.trim();

    if (normalizedEnv == production && !baseUrl.startsWith('https://')) {
      throw StateError('Production API_BASE_URL wajib HTTPS.');
    }

    return AppEnvironment(
      name: normalizedEnv,
      apiBaseUrl: _normalizeBaseUrl(baseUrl),
    );
  }

  static String _normalizeBaseUrl(String value) {
    final withoutSlash = value.endsWith('/')
        ? value.substring(0, value.length - 1)
        : value;
    return withoutSlash.endsWith('/api/v1')
        ? withoutSlash
        : '$withoutSlash/api/v1';
  }
}
