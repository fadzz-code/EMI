import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

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

String offlineDownloadErrorMessage(Object error) {
  if (error is AppError) {
    return switch (error.type) {
      AppErrorType.networkUnavailable =>
        'Koneksi internet tidak tersedia. Periksa koneksi lalu coba lagi.',
      AppErrorType.timeout ||
      AppErrorType.rateLimited => 'Unduhan belum berhasil. Silakan coba lagi.',
      AppErrorType.server =>
        'Layanan sedang mengalami gangguan. Silakan coba beberapa saat lagi.',
      AppErrorType.unauthorized || AppErrorType.forbidden =>
        'Sesi Anda telah berakhir. Silakan masuk kembali.',
      _ => 'Terjadi kendala saat mengunduh. Silakan coba lagi.',
    };
  }
  if (error is FileSystemException || error is PlatformException) {
    return 'Ruang penyimpanan tidak mencukupi untuk mengunduh konten ini.';
  }
  if (error is FormatException || error is StateError) {
    return 'Data unduhan tidak valid. Silakan coba mengunduh kembali.';
  }
  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionError =>
        'Koneksi internet tidak tersedia. Periksa koneksi lalu coba lagi.',
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Unduhan belum berhasil. Silakan coba lagi.',
      _
          when (error.response?.statusCode ?? 0) == 401 ||
              (error.response?.statusCode ?? 0) == 403 =>
        'Sesi Anda telah berakhir. Silakan masuk kembali.',
      _ when (error.response?.statusCode ?? 0) >= 500 =>
        'Layanan sedang mengalami gangguan. Silakan coba beberapa saat lagi.',
      _ => 'Terjadi kendala saat mengunduh. Silakan coba lagi.',
    };
  }
  return 'Terjadi kendala saat mengunduh. Silakan coba lagi.';
}
