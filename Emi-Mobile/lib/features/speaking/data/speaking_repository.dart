import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/dio_error_mapper.dart';
import 'speaking_models.dart';

class SpeakingRepository {
  const SpeakingRepository(this._dio, this._errorMapper);

  final Dio _dio;
  final DioErrorMapper _errorMapper;

  Future<List<SpeakingExercise>> listExercises() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/speaking/exercises',
      );
      return _list(response.data, SpeakingExercise.fromJson);
    } catch (error) {
      throw _map(error);
    }
  }

  Future<SpeakingExercise> getExercise(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/speaking/exercises/$id',
      );
      return _one(response.data, SpeakingExercise.fromJson);
    } catch (error) {
      throw _map(error);
    }
  }

  Future<List<SpeakingAttempt>> listAttempts() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/speaking/attempts',
      );
      return _list(response.data, SpeakingAttempt.fromJson);
    } catch (error) {
      throw _map(error);
    }
  }

  Future<SpeakingAttempt> getAttempt(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/student/speaking/attempts/$id',
      );
      return _one(response.data, SpeakingAttempt.fromJson);
    } catch (error) {
      throw _map(error);
    }
  }

  Future<SpeakingAttempt> submitAttempt({
    required String exerciseId,
    required SpeakingSubmissionFile file,
    int? durationSeconds,
    ProgressCallback? onSendProgress,
  }) async {
    final validation = file.validate();
    if (validation != null) {
      throw AppError(type: AppErrorType.validation, message: validation);
    }

    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.fileName,
          contentType: DioMediaType.parse(file.mimeType),
        ),
        if (durationSeconds != null)
          'audio_duration_seconds': durationSeconds.clamp(1, 30),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/student/speaking/exercises/$exerciseId/attempts',
        data: form,
        onSendProgress: onSendProgress,
      );
      return _one(response.data, SpeakingAttempt.fromJson);
    } catch (error) {
      throw _map(error);
    }
  }

  T _one<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final data = json?['data'];
    if (data is Map<String, dynamic>) return parse(data);
    throw const AppError(
      type: AppErrorType.unknown,
      message: 'Data speaking tidak valid.',
    );
  }

  List<T> _list<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final data = json?['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(parse).toList();
    }
    throw const AppError(
      type: AppErrorType.unknown,
      message: 'Data speaking tidak valid.',
    );
  }

  Object _map(Object error) {
    if (error is AppError) {
      return error;
    }
    return _errorMapper.map(error);
  }
}

Future<SpeakingSubmissionFile> speakingFileFromPath(String path) async {
  final stat = await File(path).stat();
  return SpeakingSubmissionFile(path: path, sizeBytes: stat.size);
}
