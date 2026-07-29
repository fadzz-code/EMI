import 'dart:io';

import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/app_error.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/data/admin_knowledge_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'admin knowledge parses list detail summary and processing status',
    () async {
      final repository = AdminKnowledgeRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': [
                        _item('1', 'Manual', 'manual', 'draft'),
                        _item(
                          '2',
                          'PDF',
                          'pdf',
                          'published',
                          processing: 'ready',
                        ),
                        _item('3', 'Link', 'link', 'archived'),
                      ],
                      'meta': {'current_page': 1, 'last_page': 1, 'total': 3},
                    },
                  ),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      final page = await repository.list(const AdminKnowledgeQuery());
      expect(page.total, 3);
      expect(page.items[1].processingStatus, 'ready');

      final summary = await repository.summary();
      expect(summary.total, 3);
      expect(summary.draft, 1);
      expect(summary.published, 1);
      expect(summary.archived, 1);
    },
  );

  test(
    'admin knowledge sends search status source type and pagination',
    () async {
      late Map<String, dynamic> query;
      final repository = AdminKnowledgeRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                query = Map<String, dynamic>.from(options.queryParameters);
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'data': [_item('2', 'PDF', 'pdf', 'published')],
                      'meta': {'current_page': 2, 'last_page': 3, 'total': 5},
                    },
                  ),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      final page = await repository.list(
        const AdminKnowledgeQuery(
          search: ' budaya ',
          category: 'Sejarah',
          sourceType: 'pdf',
          status: 'published',
          page: 2,
        ),
      );

      expect(query['source_type'], 'pdf');
      expect(query['search'], 'budaya');
      expect(query['status'], 'published');
      expect(query['page'], 2);
      expect(page.total, 5);
      expect(page.items.single.sourceType, 'pdf');
    },
  );

  test(
    'admin knowledge preview pdf url create update publish archive delete retry',
    () async {
      final requests = <String>[];
      final bodies = <Object?>[];
      final repository = AdminKnowledgeRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests.add('${options.method} ${options.path}');
                bodies.add(options.data);
                final data = options.path.endsWith('extract-source')
                    ? {
                        'title': 'Dokumen PDF',
                        'content': 'Isi PDF pendek',
                        'source_type': 'pdf',
                        'source_url': 'https://example.test/a.pdf',
                        'character_count': 14,
                      }
                    : _item('1', 'Judul', 'manual', 'draft');
                handler.resolve(
                  Response(requestOptions: options, data: {'data': data}),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      final preview = await repository.previewSource(
        sourceType: 'pdf',
        sourceUrl: 'https://example.test/a.pdf',
      );
      expect(preview.title, 'Dokumen PDF');
      expect(preview.characterCount, 14);

      await repository.save(
        request: const AdminKnowledgeSaveRequest(
          title: 'Judul',
          category: 'Umum',
          content: 'Isi',
          sourceType: 'manual',
          status: 'draft',
        ),
      );
      await repository.save(
        id: '1',
        request: const AdminKnowledgeSaveRequest(
          title: 'Judul',
          category: 'Umum',
          content: 'Isi',
          sourceType: 'manual',
          status: 'draft',
        ),
      );
      await repository.publish('1');
      await repository.archive('1');
      await repository.retry('1');
      await repository.delete('1');

      expect(requests, contains('POST /admin/ai/knowledge/1/retry-processing'));
      expect(
        requests,
        isNot(contains('PUT /admin/ai/knowledge/1/retry-processing')),
      );
      expect(requests, contains('POST /admin/ai/knowledge/extract-source'));
    },
  );

  test('admin knowledge PDF upload uses import endpoint', () async {
    final file = File('${Directory.systemTemp.path}/knowledge-test.pdf');
    await file.writeAsString('%PDF-1.4');
    final paths = <String>[];
    late FormData form;
    final repository = AdminKnowledgeRepository(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              paths.add(options.path);
              if (options.path.endsWith('import-pdf')) {
                form = options.data as FormData;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: options.path.endsWith('import-pdf')
                      ? {
                          'data': {'item_id': 'p1'},
                        }
                      : {'data': _item('p1', 'PDF', 'pdf', 'draft')},
                ),
              );
            },
          ),
        ),
      const DioErrorMapper(),
    );

    await repository.save(
      request: AdminKnowledgeSaveRequest(
        title: 'PDF',
        category: 'Umum',
        content: '',
        sourceType: 'pdf',
        status: 'draft',
        pdfPath: file.path,
        pdfName: 'knowledge-test.pdf',
      ),
    );

    expect(paths, contains('/admin/ai/knowledge/import-pdf'));
    expect(paths, contains('/admin/ai/knowledge/p1'));
    expect(form.files.any((file) => file.key == 'file'), isTrue);
    await file.delete();
  });

  test(
    'admin knowledge maps publish not ready malformed and network errors',
    () async {
      final conflictRepository = AdminKnowledgeRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 409,
                      data: {
                        'message': 'Sumber pengetahuan belum siap digunakan.',
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      await expectLater(
        conflictRepository.publish('p1'),
        throwsA(
          isA<AppError>().having(
            (error) => error.type,
            'type',
            AppErrorType.conflict,
          ),
        ),
      );

      final malformedRepository = AdminKnowledgeRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.resolve(
                  Response(requestOptions: options, data: {'data': []}),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      await expectLater(
        malformedRepository.detail('bad'),
        throwsA(isA<AppError>()),
      );

      final networkRepository = AdminKnowledgeRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                handler.reject(
                  DioException.connectionError(
                    requestOptions: options,
                    reason: 'offline',
                  ),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      await expectLater(
        networkRepository.list(const AdminKnowledgeQuery()),
        throwsA(isA<AppError>()),
      );
    },
  );
}

Map<String, Object?> _item(
  String id,
  String title,
  String source,
  String status, {
  String? processing,
}) => {
  'id': id,
  'title': title,
  'category': 'Umum',
  'content': 'Isi pengetahuan',
  'source_type': source,
  'source_url': source == 'manual' ? null : 'https://example.test/source',
  'status': status,
  'processing_status': processing,
  'updated_at': '2026-07-15T00:00:00Z',
};
