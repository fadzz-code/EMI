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
        // The controller also fires a background
        // GET .../conversations call on construction; only count the
        // message POST calls this test cares about.
        if (options.path.endsWith('/messages')) {
          calls += 1;
          savedOptions = options;
          savedHandler = handler;
          return;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'message': 'OK', 'data': []},
          ),
        );
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

  test('repository sends message to teacher endpoint when scoped', () async {
    final repository = ChatbotRepository(
      _dio((options, handler) {
        expect(options.path, '/teacher/chatbot/messages');
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'OK',
              'data': {
                'answer': 'Jawaban guru',
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
      basePath: '/teacher/chatbot',
    );

    final response = await repository.sendMessage('Apa itu Mekongga?');

    expect(response.answer, 'Jawaban guru');
  });

  test('repository sends conversation_id when continuing a thread', () async {
    final repository = ChatbotRepository(
      _dio((options, handler) {
        expect(options.data, {
          'message': 'Lanjut',
          'conversation_id': 'conv-1',
        });
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
                'conversation_id': 'conv-1',
              },
            },
          ),
        );
      }),
      const DioErrorMapper(),
    );

    final response = await repository.sendMessage(
      'Lanjut',
      conversationId: 'conv-1',
    );

    expect(response.conversationId, 'conv-1');
  });

  test('repository lists conversation summaries', () async {
    final repository = ChatbotRepository(
      _dio((options, handler) {
        expect(options.path, '/student/chatbot/conversations');
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'OK',
              'data': [
                {
                  'id': 'conv-1',
                  'title': 'Apa itu Mekongga?',
                  'status': 'active',
                  'last_message_at': '2026-07-30T10:00:00Z',
                  'created_at': '2026-07-30T09:00:00Z',
                },
              ],
            },
          ),
        );
      }),
      const DioErrorMapper(),
    );

    final conversations = await repository.listConversations();

    expect(conversations, hasLength(1));
    expect(conversations.first.id, 'conv-1');
    expect(conversations.first.title, 'Apa itu Mekongga?');
  });

  test('repository loads conversation detail with citations', () async {
    final repository = ChatbotRepository(
      _dio((options, handler) {
        expect(options.path, '/student/chatbot/conversations/conv-1');
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'OK',
              'data': {
                'id': 'conv-1',
                'title': 'Apa itu Mekongga?',
                'status': 'active',
                'messages': [
                  {
                    'id': 'msg-1',
                    'role': 'user',
                    'content': 'Apa itu Mekongga?',
                    'citations': [],
                  },
                  {
                    'id': 'msg-2',
                    'role': 'assistant',
                    'content': 'Mekongga adalah...',
                    'citations': [
                      {'id': 'src-1', 'title': 'Kosakata Mekongga'},
                    ],
                  },
                ],
              },
            },
          ),
        );
      }),
      const DioErrorMapper(),
    );

    final detail = await repository.getConversation('conv-1');

    expect(detail.messages, hasLength(2));
    expect(detail.messages.last.role, ChatbotMessageRole.assistant);
    expect(detail.messages.last.citations.single.title, 'Kosakata Mekongga');
  });

  test('repository deletes a conversation', () async {
    var deleted = false;
    final repository = ChatbotRepository(
      _dio((options, handler) {
        expect(options.path, '/student/chatbot/conversations/conv-1');
        deleted = true;
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'message': 'OK', 'data': []},
          ),
        );
      }),
      const DioErrorMapper(),
    );

    await repository.deleteConversation('conv-1');

    expect(deleted, isTrue);
  });

  test('controller openConversation loads history and sets active thread', () async {
    final repository = ChatbotRepository(
      _dio((options, handler) {
        if (options.path.endsWith('/conversations')) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'message': 'OK', 'data': []},
            ),
          );
          return;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'OK',
              'data': {
                'id': 'conv-1',
                'title': 'Riwayat',
                'status': 'active',
                'messages': [
                  {
                    'id': 'msg-1',
                    'role': 'user',
                    'content': 'Halo',
                    'citations': [],
                  },
                ],
              },
            },
          ),
        );
      }),
      const DioErrorMapper(),
    );
    final controller = ChatbotController(repository);

    await controller.openConversation('conv-1');

    expect(controller.state.activeConversationId, 'conv-1');
    expect(controller.state.messages, hasLength(1));
    expect(controller.state.isLoadingHistory, isFalse);
    controller.dispose();
  });

  test('controller startNewSession clears active thread and messages', () async {
    final repository = ChatbotRepository(
      _dio((options, handler) {
        if (options.path.endsWith('/conversations')) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'message': 'OK', 'data': []},
            ),
          );
          return;
        }
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
                'conversation_id': 'conv-2',
              },
            },
          ),
        );
      }),
      const DioErrorMapper(),
    );
    final controller = ChatbotController(repository);

    await controller.send('Halo');
    expect(controller.state.activeConversationId, 'conv-2');
    expect(controller.state.messages, isNotEmpty);

    controller.startNewSession();

    expect(controller.state.activeConversationId, isNull);
    expect(controller.state.messages, isEmpty);
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
