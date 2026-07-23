import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/culture/data/culture_models.dart';
import 'package:emi_mobile/features/culture/data/culture_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps culture page json', () {
    final page = CulturePage.fromJson({
      'data': [
        {
          'id': 'culture-1',
          'class_id': 'class-1',
          'title': 'Budaya Mekongga',
          'description': 'Konten budaya',
          'content_type': 'image',
          'status': 'published',
          'media': {'id': 'media-1', 'url': 'https://example.test/image.jpg'},
          'school_class': {
            'id': 'class-1',
            'name': 'VII A',
            'school': {'name': 'SMP EMI'},
          },
        },
      ],
      'meta': {'current_page': 1, 'last_page': 2, 'total': 1},
    });

    expect(page.items.single.title, 'Budaya Mekongga');
    expect(page.items.single.contentUrl, 'https://example.test/image.jpg');
    expect(page.items.single.schoolClass?.schoolName, 'SMP EMI');
    expect(page.hasNextPage, isTrue);
  });

  test('culture query keeps stable provider identity', () {
    expect(const CultureQuery(), const CultureQuery());
    expect(const CultureQuery().hashCode, const CultureQuery().hashCode);
    expect(const CultureQuery(page: 2), isNot(const CultureQuery()));
  });

  test('repository maps success response', () async {
    final repository = CultureRepository(
      _dio((options, handler) {
        expect(options.path, '/student/culture');
        expect(options.queryParameters['page'], 1);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'OK',
              'data': [
                {
                  'id': 'culture-1',
                  'class_id': 'class-1',
                  'title': 'Budaya',
                  'content_type': 'article',
                  'status': 'published',
                },
              ],
              'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
            },
          ),
        );
      }),
      const DioErrorMapper(),
    );

    final page = await repository.list();

    expect(page.items.single.id, 'culture-1');
    expect(page.hasNextPage, isFalse);
  });

  test(
    'repository resolves private culture media with temporary URL',
    () async {
      final repository = CultureRepository(
        _dio((options, handler) {
          expect(options.path, '/media/media-1/temporary-url');
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {'url': 'https://example.test/private.mp3'},
              },
            ),
          );
        }),
        const DioErrorMapper(),
      );
      final item = CultureItem.fromJson({
        'id': 'culture-1',
        'class_id': 'class-1',
        'title': 'Audio',
        'content_type': 'audio',
        'status': 'published',
        'media': {
          'id': 'media-1',
          'visibility': 'private',
          'url': '/api/v1/media/media-1',
        },
      });

      expect(
        await repository.playbackUrl(item),
        'https://example.test/private.mp3',
      );
    },
  );

  test('repository maps backend error', () async {
    final repository = CultureRepository(
      _dio((options, handler) {
        handler.reject(
          DioException.badResponse(
            statusCode: 500,
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 500,
              data: {'message': 'Server gagal.'},
            ),
          ),
        );
      }),
      const DioErrorMapper(),
    );

    expect(
      repository.list(),
      throwsA(
        isA<AppError>().having(
          (error) => error.type,
          'type',
          AppErrorType.server,
        ),
      ),
    );
  });
}

Dio _dio(void Function(RequestOptions, RequestInterceptorHandler) onRequest) {
  return Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(InterceptorsWrapper(onRequest: onRequest));
}
