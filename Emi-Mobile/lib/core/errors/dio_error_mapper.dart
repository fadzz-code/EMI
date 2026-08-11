import 'package:dio/dio.dart';

import 'app_error.dart';

class DioErrorMapper {
  const DioErrorMapper();

  AppError map(Object error) {
    if (error is! DioException) {
      return const AppError(
        type: AppErrorType.unknown,
        message: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const AppError(
        type: AppErrorType.timeout,
        message:
            'Koneksi ke server terlalu lama. Periksa jaringan lalu coba lagi.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return const AppError(
        type: AppErrorType.networkUnavailable,
        message: 'Tidak dapat terhubung ke server EMI.',
      );
    }

    final statusCode = error.response?.statusCode ?? 0;
    final data = error.response?.data;
    final message = _messageFrom(data) ?? _fallbackMessage(statusCode);
    final errors = _errorsFrom(data);

    return AppError(
      type: _typeFromStatus(statusCode),
      message: message,
      fieldErrors: errors,
    );
  }

  AppErrorType _typeFromStatus(int statusCode) {
    return switch (statusCode) {
      401 => AppErrorType.unauthorized,
      403 => AppErrorType.forbidden,
      404 => AppErrorType.notFound,
      409 => AppErrorType.conflict,
      422 => AppErrorType.validation,
      429 => AppErrorType.rateLimited,
      >= 500 => AppErrorType.server,
      _ => AppErrorType.unknown,
    };
  }

  String _fallbackMessage(int statusCode) {
    return switch (statusCode) {
      401 => 'Sesi Anda tidak valid. Silakan login kembali.',
      403 => 'Anda tidak memiliki izin untuk membuka data ini.',
      404 => 'Data tidak ditemukan.',
      409 => 'Terdapat konflik pada data.',
      422 => 'Data yang diberikan belum valid.',
      429 => 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.',
      >= 500 => 'Layanan sedang bermasalah. Coba lagi beberapa saat lagi.',
      _ => 'Permintaan API gagal.',
    };
  }

  String? _messageFrom(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return null;
  }

  Map<String, List<String>> _errorsFrom(Object? data) {
    if (data is! Map<String, dynamic>) return const {};
    final errors = data['errors'];
    if (errors is! Map<String, dynamic>) return const {};

    return errors.map((key, value) {
      final list = value is List
          ? value.whereType<String>().toList()
          : <String>[];
      return MapEntry(key, list);
    });
  }
}
