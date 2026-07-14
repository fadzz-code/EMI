import 'dart:io';

import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/data/admin_crud_providers.dart';
import 'package:emi_mobile/features/admin/data/admin_crud_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'admin dictionary parses page detail nullable category and audio',
    () async {
      final repository = AdminCrudRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': [
                        {
                          'id': 'd1',
                          'category_id': 'c1',
                          'category': {'id': 'c1', 'name': 'Kegiatan'},
                          'indonesia': 'Pulang',
                          'english': 'Go home',
                          'mekongga': 'Mowali',
                          'example_mekongga': null,
                          'example_indonesia': null,
                          'audio': {
                            'id': 'm1',
                            'url': 'https://example.test/a.mp3',
                          },
                          'status': 'active',
                        },
                        {
                          'id': 'd2',
                          'category_id': '',
                          'category': null,
                          'indonesia': 'Makan',
                          'english': 'Eat',
                          'mekongga': 'Mokoni',
                          'audio': null,
                          'status': 'inactive',
                        },
                      ],
                      'meta': {'current_page': 1, 'last_page': 2, 'total': 16},
                    },
                  ),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      final page = await repository.dictionary();

      expect(page.hasMore, isTrue);
      expect(page.currentPage, 1);
      expect(page.lastPage, 2);
      expect(page.total, 16);
      expect(page.items.first.categoryName, 'Kegiatan');
      expect(page.items.first.audioMediaId, 'm1');
      expect(page.items.first.audioUrl, 'https://example.test/a.mp3');
      expect(page.items.last.categoryName, isNull);
      expect(page.items.last.audioUrl, isNull);
    },
  );

  test('admin dictionary sends search category status pagination', () async {
    late Map<String, dynamic> query;
    final repository = AdminCrudRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              query = Map<String, dynamic>.from(options.queryParameters);
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'data': [],
                    'meta': {'current_page': 2, 'last_page': 2, 'total': 15},
                  },
                ),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );

    await repository.dictionary(
      search: ' mowali ',
      categoryId: 'c1',
      status: 'active',
      page: 2,
    );

    expect(query, {
      'page': 2,
      'per_page': 15,
      'search': 'mowali',
      'category_id': 'c1',
      'status': 'active',
    });
  });

  test('admin dictionary create update delete contracts', () async {
    final requests = <String>[];
    final bodies = <Object?>[];
    final repository = AdminCrudRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              bodies.add(options.data);
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'data': {
                      'id': 'd1',
                      'category_id': 'c1',
                      'indonesia': 'Pulang',
                      'english': 'Go home',
                      'mekongga': 'Mowali',
                      'status': 'active',
                    },
                  },
                ),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );
    final body = {
      'category_id': 'c1',
      'indonesia': 'Pulang',
      'english': 'Go home',
      'mekongga': 'Mowali',
      'example_mekongga': null,
      'example_indonesia': null,
      'status': 'active',
    };

    await repository.saveDictionary(data: body);
    await repository.saveDictionary(id: 'd1', data: body);
    await repository.deleteDictionary('d1');

    expect(requests, [
      'POST /admin/dictionary/entries',
      'PUT /admin/dictionary/entries/d1',
      'DELETE /admin/dictionary/entries/d1',
    ]);
    expect(bodies.first, body);
    expect(bodies[1], body);
  });

  test(
    'admin dictionary maps duplicate validation auth and network errors',
    () async {
      Future<AppError> failWith(Object error) async {
        final repository = AdminCrudRepository(
          Dio(BaseOptions(baseUrl: 'https://example.test'))
            ..interceptors.add(
              InterceptorsWrapper(
                onRequest: (options, handler) {
                  if (error is DioException) {
                    handler.reject(error);
                  } else {
                    handler.reject(
                      DioException(
                        requestOptions: options,
                        error: error,
                        type: DioExceptionType.connectionError,
                      ),
                    );
                  }
                },
              ),
            ),
          const DioErrorMapper(),
        );
        try {
          await repository.dictionary();
          fail('expected AppError');
        } catch (error) {
          return error as AppError;
        }
      }

      DioException responseError(int status, String code) => DioException(
        requestOptions: RequestOptions(path: '/admin/dictionary/entries'),
        response: Response(
          requestOptions: RequestOptions(path: '/admin/dictionary/entries'),
          statusCode: status,
          data: {'message': code, 'code': code},
        ),
      );

      expect(
        (await failWith(responseError(409, 'DICTIONARY_DUPLICATE'))).type,
        AppErrorType.conflict,
      );
      expect(
        (await failWith(responseError(422, 'VALIDATION_ERROR'))).type,
        AppErrorType.validation,
      );
      expect(
        (await failWith(responseError(403, 'FORBIDDEN'))).type,
        AppErrorType.forbidden,
      );
      expect(
        (await failWith(responseError(401, 'UNAUTHENTICATED'))).type,
        AppErrorType.unauthorized,
      );
      expect(
        (await failWith(Exception('offline'))).type,
        AppErrorType.networkUnavailable,
      );
    },
  );

  test('admin dictionary category and import contracts', () async {
    final requests = <String>[];
    final temp =
        await File(
          '${Directory.systemTemp.path}/emi_dictionary_test.csv',
        ).writeAsString(
          'kode,indonesia,english,mekongga,kategori,audio_filename\n',
        );
    final repository = AdminCrudRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add('${options.method} ${options.path}');
              final data = switch (options.path) {
                '/admin/dictionary/categories' => {
                  'data': {
                    'id': 'c1',
                    'name': 'Benda',
                    'status': 'active',
                    'entries_count': 2,
                  },
                },
                '/admin/dictionary/imports/preview' => {
                  'data': {
                    'id': 'job-1',
                    'status': 'previewed',
                    'total_rows': 1,
                    'valid_rows': 1,
                    'invalid_rows': 0,
                  },
                },
                '/admin/dictionary/imports/job-1/confirm' => {
                  'data': {
                    'id': 'job-1',
                    'status': 'completed',
                    'inserted_rows': 1,
                    'updated_rows': 0,
                    'skipped_rows': 0,
                    'invalid_rows': 0,
                  },
                },
                '/admin/dictionary/imports/job-1/errors' => {
                  'data': [
                    {
                      'id': 'e1',
                      'row_number': 4,
                      'field': 'mekongga',
                      'code': 'REQUIRED',
                      'message': 'Kata Mekongga wajib diisi.',
                    },
                  ],
                  'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
                },
                _ => {
                  'data': {'id': 'c1', 'name': 'Benda'},
                },
              };
              handler.resolve(Response(requestOptions: options, data: data));
            },
          ),
        ),
      const DioErrorMapper(),
    );

    final category = await repository.saveCategory(
      data: {'name': 'Benda', 'description': null, 'status': 'active'},
    );
    final preview = await repository.previewDictionaryImport(csvFile: temp);
    final confirmed = await repository.confirmDictionaryImport(preview.id);
    final errors = await repository.dictionaryImportErrors(preview.id);
    await repository.deleteCategory(category.id);

    expect(category.entriesCount, 2);
    expect(preview.totalRows, 1);
    expect(confirmed.insertedRows, 1);
    expect(errors.items.single.rowNumber, 4);
    expect(requests, [
      'POST /admin/dictionary/categories',
      'POST /admin/dictionary/imports/preview',
      'POST /admin/dictionary/imports/job-1/confirm',
      'GET /admin/dictionary/imports/job-1/errors',
      'DELETE /admin/dictionary/categories/c1',
    ]);
  });

  test('admin dictionary query identity includes filters', () {
    const a = AdminSearchQuery(
      search: 'mowali',
      categoryId: 'c1',
      status: 'active',
      page: 2,
    );
    const b = AdminSearchQuery(
      search: 'mowali',
      categoryId: 'c1',
      status: 'active',
      page: 2,
    );
    const c = AdminSearchQuery(search: 'mowali', status: 'inactive', page: 2);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });
}
