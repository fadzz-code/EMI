import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/chatbot/data/chatbot_models.dart';
import 'package:emi_mobile/features/chatbot/data/chatbot_repository.dart';
import 'package:emi_mobile/features/chatbot/presentation/chatbot_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps chatbot response and source', () {
    final response = ChatbotResponse.fromJson({
      'answer': 'Jawaban',
      'matched': true,
      'mode': 'default_extractive',
      'provider': 'default',
      'confidence': 83,
      'source': {
        'id': 'src-1',
        'title': 'Kosakata Mekongga',
        'category': 'Kamus',
        'source_type': 'manual',
        'source_url': null,
      },
    });

    expect(response.answer, 'Jawaban');
    expect(response.matched, isTrue);
    expect(response.source?.title, 'Kosakata Mekongga');
    expect(response.confidence, 83);
  });

  test('keeps user then assistant ordering', () {
    const messages = [
      ChatbotMessage(
        id: '1',
        role: ChatbotMessageRole.user,
        content: 'Apa itu Mekongga?',
      ),
      ChatbotMessage(
        id: '2',
        role: ChatbotMessageRole.assistant,
        content: 'Mekongga adalah...',
      ),
    ];

    expect(messages.first.role, ChatbotMessageRole.user);
    expect(messages.last.role, ChatbotMessageRole.assistant);
  });

  test('repository sends message and maps success response', () async {
    final repository = ChatbotRepository(
      _dio((options, handler) {
        expect(options.path, '/student/chatbot/messages');
        expect(options.data, {'message': 'Apa itu Mekongga?'});
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'OK',
              'data': {
                'answer': 'Jawaban',
                'matched': false,
                'mode': 'default_extractive',
                'provider': 'default',
                'source': null,
              },
            },
          ),
        );
      }),
      const DioErrorMapper(),
    );

    final response = await repository.sendMessage('Apa itu Mekongga?');

    expect(response.answer, 'Jawaban');
    expect(response.matched, isFalse);
  });

  test('controller prevents double-send while request pending', () async {
    var calls = 0;
    late RequestInterceptorHandler savedHandler;
    late RequestOptions savedOptions;
    final repository = ChatbotRepository(
      _dio((options, handler) {
        calls += 1;
        savedOptions = options;
        savedHandler = handler;
      }),
      const DioErrorMapper(),
    );
    final controller = ChatbotController(repository);

    final first = controller.send('Apa itu Mekongga?');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await controller.send('Apa itu Mekongga?');

    expect(calls, 1);
    savedHandler.resolve(
      Response(
        requestOptions: savedOptions,
        statusCode: 200,
        data: {
          'success': true,
          'message': 'OK',
          'data': {
            'answer': 'Jawaban',
            'matched': false,
            'mode': 'default_extractive',
            'provider': 'default',
            'source': null,
          },
        },
      ),
    );
    await first;

    expect(controller.state.messages, hasLength(2));
    expect(controller.state.isSending, isFalse);
    controller.dispose();
  });

  test('repository maps validation error', () async {
    final repository = ChatbotRepository(
      _dio((options, handler) {
        handler.reject(
          DioException.badResponse(
            statusCode: 422,
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 422,
              data: {
                'message': 'Data yang diberikan belum valid.',
                'errors': {
                  'message': ['Pertanyaan minimal 2 karakter.'],
                },
              },
            ),
          ),
        );
      }),
      const DioErrorMapper(),
    );

    expect(
      repository.sendMessage('x'),
      throwsA(
        isA<AppError>().having(
          (error) => error.type,
          'type',
          AppErrorType.validation,
        ),
      ),
    );
  });
}

Dio _dio(void Function(RequestOptions, RequestInterceptorHandler) onRequest) {
  return Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(InterceptorsWrapper(onRequest: onRequest));
}
