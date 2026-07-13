class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.code,
    this.errors,
  });

  final bool success;
  final String message;
  final T? data;
  final String? code;
  final Map<String, List<String>>? errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parseData,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message'] as String? ?? '',
      data: json.containsKey('data') ? parseData(json['data']) : null,
      code: json['code'] as String?,
      errors: _errorsFrom(json['errors']),
    );
  }

  static Map<String, List<String>>? _errorsFrom(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return value.map((key, item) {
      final list = item is List
          ? item.whereType<String>().toList()
          : <String>[];
      return MapEntry(key, list);
    });
  }
}
