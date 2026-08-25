import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/admin/data/admin_modules_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'admin module repository list detail create update and actions',
    () async {
      final requests = <String>[];
      final bodies = <Object?>[];
      final repository = AdminModuleRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests.add('${options.method} ${options.path}');
                bodies.add(options.data);
                final data = _module('m1', lessons: [_lesson('l1')]);
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data:
                        options.method == 'GET' &&
                            (options.path == '/admin/module-templates' ||
                                options.path == '/classes')
                        ? {
                            'data': [data],
                            'meta': {
                              'current_page': 1,
                              'last_page': 1,
                              'total': 1,
                            },
                          }
                        : {'data': data},
                  ),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      final page = await repository.list(
        const AdminModuleQuery(search: ' dasar ', status: 'published'),
      );
      expect(page.items.single.lessonsCount, 1);
      expect(await repository.summary().then((value) => value.published), 1);
      expect(
        await repository.activeClasses().then((value) => value.single.id),
        'm1',
      );
      expect(
        await repository.detail('m1').then((value) => value.lessons.single.id),
        'l1',
      );
      await repository.save(
        request: const AdminModuleSaveRequest(
          title: 'A',
          description: 'B',
          status: 'draft',
        ),
      );
      await repository.save(
        id: 'm1',
        request: const AdminModuleSaveRequest(
          title: 'A',
          description: 'B',
          status: 'archived',
        ),
      );
      await repository.publish(
        'm1',
        applyToAllActiveClasses: true,
        publishClassModules: true,
      );
      await repository.archive('m1');
      await repository.apply('m1', const ['c1'], publishClassModules: true);
      await repository.delete('m1');

      expect(requests, contains('GET /admin/module-templates'));
      expect(requests, contains('POST /admin/module-templates'));
      expect(requests, contains('PUT /admin/module-templates/m1'));
      expect(requests, contains('POST /admin/module-templates/m1/publish'));
      expect(requests, contains('POST /admin/module-templates/m1/archive'));
      expect(requests, contains('POST /admin/module-templates/m1/apply'));
      expect(requests, contains('DELETE /admin/module-templates/m1'));
      expect(
        bodies.whereType<Map>().any(
          (body) =>
              body['apply_to_all_active_classes'] == true &&
              body['publish_class_modules'] == true,
        ),
        isTrue,
      );
      expect(
        bodies.whereType<Map>().any(
          (body) =>
              body['class_ids'] is List &&
              body['class_ids'].first == 'c1' &&
              body['publish_class_modules'] == true,
        ),
        isTrue,
      );
    },
  );

  test(
    'admin lesson repository media upload temporary url and reorder',
    () async {
      final requests = <String>[];
      final bodies = <Object?>[];
      final repository = AdminModuleRepository(
        Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests.add('${options.method} ${options.path}');
                bodies.add(options.data);
                Object data = _lesson('l1');
                if (options.path == '/media') {
                  data = {
                    'id': 'media1',
                    'original_name': 'gambar.png',
                    'mime_type': 'image/png',
                    'size_bytes': 100,
                    'url': 'https://example.test/public/media/media1/content',
                  };
                }
                if (options.path.endsWith('/temporary-url')) {
                  data = {
                    'url': 'https://example.test/signed',
                    'expires_at': '2026-07-15T00:00:00Z',
                  };
                }
                if (options.method == 'GET' &&
                    options.path.endsWith('/lessons')) {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      data: {
                        'data': [_lesson('l1'), _lesson('l2')],
                      },
                    ),
                  );
                  return;
                }
                handler.resolve(
                  Response(requestOptions: options, data: {'data': data}),
                );
              },
            ),
          ),
        const DioErrorMapper(),
      );

      final lessons = await repository.lessons('m1');
      expect(lessons.length, 2);
      final uploaded = await repository.uploadMedia(
        path: 'pubspec.yaml',
        name: 'gambar.png',
        purpose: 'lesson_image',
        visibility: 'public',
      );
      expect(uploaded.id, 'media1');
      expect(
        await repository.temporaryUrl('media1').then((value) => value.url),
        contains('signed'),
      );
      await repository.saveLesson(
        moduleId: 'm1',
        request: const AdminLessonSaveRequest(
          title: 'Gambar',
          description: '',
          contentType: 'image',
          contentBody: '',
          mediaId: 'media1',
          externalUrl: '',
          sortOrder: null,
          status: 'published',
        ),
      );
      await repository.saveLesson(
        moduleId: 'm1',
        id: 'l1',
        request: const AdminLessonSaveRequest(
          title: 'Link',
          description: '',
          contentType: 'link',
          contentBody: '',
          mediaId: '',
          externalUrl: 'https://example.test',
          sortOrder: null,
          status: 'draft',
        ),
      );
      await repository.reorderLessons('m1', const ['l2', 'l1']);

      expect(requests, contains('POST /media'));
      expect(requests, contains('POST /media/media1/temporary-url'));
      expect(requests, contains('POST /admin/module-templates/m1/lessons'));
      expect(requests, contains('PUT /admin/lesson-templates/l1'));
      expect(
        requests,
        contains('PATCH /admin/module-templates/m1/lessons/reorder'),
      );
      expect((bodies.last as Map)['lesson_ids'], ['l2', 'l1']);
    },
  );
}

Map<String, dynamic> _module(
  String id, {
  List<Map<String, dynamic>> lessons = const [],
}) => {
  'id': id,
  'title': 'Kosakata Dasar',
  'description': 'Modul global',
  'status': 'published',
  'lessons_count': lessons.length,
  'lessons': lessons,
  'created_at': '2026-07-15T00:00:00Z',
  'updated_at': '2026-07-15T00:00:00Z',
};

Map<String, dynamic> _lesson(String id) => {
  'id': id,
  'module_template_id': 'm1',
  'title': 'Salam',
  'description': '',
  'content_type': 'text',
  'content_body': 'Halo',
  'sort_order': id == 'l1' ? 1 : 2,
  'status': 'published',
  'created_at': '2026-07-15T00:00:00Z',
  'updated_at': '2026-07-15T00:00:00Z',
};
