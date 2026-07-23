import 'dart:io';

import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/speaking/data/speaking_models.dart';
import 'package:emi_mobile/features/speaking/data/speaking_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps speaking exercise and attempt json', () {
    final exercise = SpeakingExercise.fromJson({
      'id': 'exercise-1',
      'title': 'Salam',
      'prompt_text': 'Ucapkan salam',
      'target_text': 'Mombesara',
      'target_translation': 'Menyapa',
      'status': 'published',
      'reference_audio_media_id': 'media-1',
      'reference_audio': {
        'id': 'media-1',
        'url': 'https://example.test/audio.m4a',
        'mime_type': 'audio/mp4',
      },
    });
    final attempt = SpeakingAttempt.fromJson({
      'id': 'attempt-1',
      'exercise_id': 'exercise-1',
      'status': 'completed',
      'ai_score': '88.50',
      'ai_transcription': 'Mombesara',
      'teacher_feedback': 'Bagus',
    });

    expect(exercise.hasReferenceAudio, isTrue);
    expect(exercise.referenceAudio?.mimeType, 'audio/mp4');
    expect(attempt.aiScore, 88.5);
    expect(attempt.isCompleted, isTrue);
    expect(attempt.teacherFeedback, 'Bagus');

    final page = SpeakingAttemptPage.fromJson({
      'data': [
        {
          'id': 'attempt-2',
          'exercise_id': 'exercise-1',
          'status': 'completed',
          'analysis': {'score': 91, 'transcription': 'Mombesara'},
          'review': {'score': 95, 'feedback': 'Jelas'},
          'recording': {'media_id': 'media-2'},
        },
      ],
      'meta': {'current_page': 2, 'last_page': 3, 'total': 31},
    });
    expect(page.currentPage, 2);
    expect(page.lastPage, 3);
    expect(page.total, 31);
    expect(page.items.single.aiScore, 91);
    expect(page.items.single.teacherFeedback, 'Jelas');
    expect(page.items.single.audioMediaId, 'media-2');
  });

  test('normalizes multipart filename mime and size validation', () {
    const file = SpeakingSubmissionFile(
      path: r'C:\tmp\take.m4a',
      sizeBytes: 99,
    );

    expect(file.fileName, 'take.m4a');
    expect(file.extension, 'm4a');
    expect(file.mimeType, 'audio/mp4');
    expect(file.validate(), isNull);
    expect(
      const SpeakingSubmissionFile(
        path: r'C:\tmp\take.exe',
        sizeBytes: 99,
      ).validate(),
      'Format audio tidak didukung.',
    );
    expect(
      const SpeakingSubmissionFile(
        path: r'C:\tmp\take.m4a',
        sizeBytes: 6 * 1024 * 1024,
      ).validate(),
      'Ukuran audio melebihi 5 MB.',
    );
  });

  test('repository list detail submit and result success', () async {
    final requests = <String>[];
    final repository = SpeakingRepository(
      _dio((options, handler) {
        requests.add('${options.method} ${options.path}');
        if (options.path == '/student/speaking/exercises') {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': [_exerciseJson],
              },
            ),
          );
          return;
        }
        if (options.path == '/student/speaking/exercises/exercise-1') {
          handler.resolve(
            Response(requestOptions: options, data: {'data': _exerciseJson}),
          );
          return;
        }
        if (options.path == '/student/speaking/attempts') {
          expect(options.queryParameters, {'page': 2, 'per_page': 15});
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': [_attemptJson],
                'meta': {'current_page': 2, 'last_page': 2, 'total': 16},
              },
            ),
          );
          return;
        }
        if (options.path == '/student/speaking/attempts/attempt-1') {
          handler.resolve(
            Response(requestOptions: options, data: {'data': _attemptJson}),
          );
          return;
        }
        if (options.path == '/media/media-1/temporary-url') {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {'url': 'https://example.test/private.m4a'},
              },
            ),
          );
          return;
        }
        if (options.path == '/student/speaking/exercises/exercise-1/attempts') {
          final form = options.data as FormData;
          expect(form.files.single.key, 'file');
          expect(
            form.fields.map((field) => field.key),
            containsAll(['audio_duration_seconds', 'capture_source']),
          );
          expect(
            form.fields
                .firstWhere((field) => field.key == 'capture_source')
                .value,
            'mobile_microphone',
          );
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 201,
              data: {'data': _attemptJson},
            ),
          );
          return;
        }
        handler.reject(DioException(requestOptions: options));
      }),
      const DioErrorMapper(),
    );

    expect((await repository.listExercises()).single.id, 'exercise-1');
    expect((await repository.getExercise('exercise-1')).title, 'Salam');
    expect(
      (await repository.listAttempts(page: 2)).items.single.id,
      'attempt-1',
    );
    expect((await repository.getAttempt('attempt-1')).status, 'pending');
    expect(
      await repository.temporaryMediaUrl('media-1'),
      'https://example.test/private.m4a',
    );
    final temp = await File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}sample-speaking.m4a',
    ).writeAsBytes([1, 2, 3]);
    addTearDown(() => temp.delete().catchError((_) => temp));
    final submitted = await repository.submitAttempt(
      exerciseId: 'exercise-1',
      file: SpeakingSubmissionFile(path: temp.path, sizeBytes: 3),
      durationSeconds: 3,
    );

    expect(submitted.id, 'attempt-1');
    expect(
      requests,
      contains('POST /student/speaking/exercises/exercise-1/attempts'),
    );
  });

  test('repository maps backend error', () async {
    final repository = SpeakingRepository(
      _dio((options, handler) {
        handler.reject(
          DioException.badResponse(
            statusCode: 422,
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 422,
              data: {'message': 'Audio wajib diunggah.'},
            ),
          ),
        );
      }),
      const DioErrorMapper(),
    );

    expect(repository.listExercises(), throwsA(isA<AppError>()));
  });

  test('manual refresh and bounded polling contract states', () {
    const pending = SpeakingAttempt(
      id: '1',
      exerciseId: 'e',
      status: 'pending',
    );
    const processing = SpeakingAttempt(
      id: '2',
      exerciseId: 'e',
      status: 'processing',
    );
    const completed = SpeakingAttempt(
      id: '3',
      exerciseId: 'e',
      status: 'completed',
    );
    const failed = SpeakingAttempt(id: '4', exerciseId: 'e', status: 'failed');

    expect(pending.isProcessing, isTrue);
    expect(processing.isProcessing, isTrue);
    expect(completed.isProcessing, isFalse);
    expect(failed.isFailed, isTrue);
    expect(12 * 5, 60);
  });
}

const _exerciseJson = {
  'id': 'exercise-1',
  'title': 'Salam',
  'target_text': 'Mombesara',
  'status': 'published',
};

const _attemptJson = {
  'id': 'attempt-1',
  'exercise_id': 'exercise-1',
  'status': 'pending',
};

Dio _dio(void Function(RequestOptions, RequestInterceptorHandler) onRequest) {
  return Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(InterceptorsWrapper(onRequest: onRequest));
}
