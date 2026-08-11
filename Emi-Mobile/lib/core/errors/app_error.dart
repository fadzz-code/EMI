enum AppErrorType {
  networkUnavailable,
  timeout,
  unauthorized,
  forbidden,
  validation,
  notFound,
  conflict,
  rateLimited,
  server,
  unknown,
}

class AppError implements Exception {
  const AppError({
    required this.type,
    required this.message,
    this.fieldErrors = const {},
  });

  final AppErrorType type;
  final String message;
  final Map<String, List<String>> fieldErrors;

  @override
  String toString() => message;
}
