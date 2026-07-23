import 'dart:io';

import 'package:dio/dio.dart';
import 'package:emi_mobile/core/errors/dio_error_mapper.dart';
import 'package:emi_mobile/features/teacher/data/teacher_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<RequestOptions> requests;
  late TeacherRepository repository;

  setUp(() {
    requests = [];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final lesson = {
            'id': 'lesson-1',
            'title': 'Sapaan',
            'description': 'Dasar',
            'content_type': 'text',
            'content_body': 'Halo',
            'sort_order': 2,
            'status': 'draft',
            'media': {
              'id': 'media-1',
              'original_name': 'sapaan.pdf',
              'mime_type': 'application/pdf',
            },
          };
          final requestData = options.data is Map
              ? options.data as Map
              : const {};
          final module = {
            'id': 'module-1',
            'class_id': 'class-1',
            'title': requestData['title'] ?? 'Bahasa Mekongga',
            'description': requestData['description'] ?? 'Pengantar',
            'sort_order': requestData['sort_order'] ?? 1,
            'status': options.path.endsWith('/publish')
                ? 'published'
                : options.path.endsWith('/archive')
                ? 'archived'
                : 'draft',
            'lessons': [lesson],
          };
          final data = switch (options.path) {
            '/classes/class-1/modules' when options.method == 'GET' => {
              'data': [module],
            },
            '/class-lessons/lesson-1' ||
            '/class-lessons/lesson-1/publish' => {'data': lesson},
            '/media' => {
              'data': {'id': 'media-2', 'original_name': 'baru.pdf'},
            },
            _ => {'data': module},
          };
          handler.resolve(Response(requestOptions: options, data: data));
        },
      ),
    );
    repository = TeacherRepository(dio, const DioErrorMapper());
  });

  test('lists active class modules with web query contract', () async {
    final result = await repository.modules('class-1');
    expect(result.single.title, 'Bahasa Mekongga');
    expect(result.single.lessons.single.mediaName, 'sapaan.pdf');
    expect(requests.single.path, '/classes/class-1/modules');
    expect(requests.single.queryParameters, {
      'per_page': 100,
      'sort_by': 'sort_order',
      'sort_direction': 'asc',
    });
  });

  test('updates module fields and returns the new baseline', () async {
    final updated = await repository.updateModule('module-1', {
      'title': 'Baru',
      'description': 'Deskripsi baru',
      'sort_order': 3,
    });
    expect(updated.title, 'Baru');
    expect(updated.description, 'Deskripsi baru');
    expect(updated.sortOrder, 3);
    expect(updated.classId, 'class-1');
    expect(requests.single.method, 'PUT');
    expect(requests.single.path, '/class-modules/module-1');
    expect(requests.single.data, {
      'title': 'Baru',
      'description': 'Deskripsi baru',
      'sort_order': 3,
    });
  });

  test('creates module scoped by active class with draft payload', () async {
    final created = await repository.createModule('class-1', {
      'title': 'Baru',
      'description': 'Deskripsi',
      'sort_order': 2,
    });
    expect(created.title, 'Baru');
    expect(requests.single.method, 'POST');
    expect(requests.single.path, '/classes/class-1/modules');
    expect(requests.single.data, {
      'title': 'Baru',
      'description': 'Deskripsi',
      'sort_order': 2,
    });
    expect((requests.single.data as Map).containsKey('class_id'), isFalse);
    expect((requests.single.data as Map).containsKey('status'), isFalse);
  });

  test(
    'archives and deletes module through backend lifecycle endpoints',
    () async {
      expect((await repository.archiveModule('module-1')).status, 'archived');
      await repository.deleteModule('module-1');
      expect(requests.map((item) => '${item.method} ${item.path}'), [
        'POST /class-modules/module-1/archive',
        'DELETE /class-modules/module-1',
      ]);
    },
  );

  test('publishes module and lesson through action endpoints', () async {
    await repository.publishModule('module-1');
    await repository.publishLesson('lesson-1');
    expect(requests.map((item) => item.path), [
      '/class-modules/module-1/publish',
      '/class-lessons/lesson-1/publish',
    ]);
    expect(requests.every((item) => item.method == 'POST'), isTrue);
  });

  test(
    'uploads lesson media with backend purpose and visibility fields',
    () async {
      final file = File('${Directory.systemTemp.path}/lesson.pdf');
      await file.writeAsBytes([37, 80, 68, 70]);
      try {
        final result = await repository.uploadMedia(
          file.path,
          'lesson.pdf',
          purpose: 'document',
        );
        expect(result.id, 'media-2');
        final request = requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/media');
        final form = request.data as FormData;
        expect(
          form.fields,
          containsAll([
            predicate<MapEntry<String, String>>(
              (entry) => entry.key == 'purpose' && entry.value == 'document',
            ),
            predicate<MapEntry<String, String>>(
              (entry) => entry.key == 'visibility' && entry.value == 'private',
            ),
          ]),
        );
        expect(form.files.single.key, 'file');
        expect(form.files.single.value.filename, 'lesson.pdf');
      } finally {
        await file.delete();
      }
    },
  );

  test('updates PDF lesson with uploaded media id and content type', () async {
    await repository.updateLesson('lesson-1', {
      'title': 'Dokumen Baru',
      'description': 'PDF terbaru',
      'content_type': 'pdf',
      'sort_order': 2,
      'media_id': 'media-2',
    });
    expect(requests.single.method, 'PUT');
    expect(requests.single.path, '/class-lessons/lesson-1');
    expect(requests.single.data, {
      'title': 'Dokumen Baru',
      'description': 'PDF terbaru',
      'content_type': 'pdf',
      'sort_order': 2,
      'media_id': 'media-2',
    });
    expect((requests.single.data as Map).containsKey('content_body'), isFalse);
  });

  test('updates lesson content and supports media removal', () async {
    await repository.updateLesson('lesson-1', {
      'title': 'Sapaan Baru',
      'content_body': 'Hai',
      'sort_order': 4,
      'media_id': null,
    });
    expect(requests.single.path, '/class-lessons/lesson-1');
    expect(requests.single.data, {
      'title': 'Sapaan Baru',
      'content_body': 'Hai',
      'sort_order': 4,
      'media_id': null,
    });
  });

  test('parses safe defaults without exposing media id as label', () {
    final lesson = TeacherLesson.fromJson({
      'media': {'id': 'secret-path'},
    });
    expect(lesson.title, 'Materi tanpa judul');
    expect(lesson.mediaName, isNull);
    expect(lesson.sortOrder, 1);
  });
}
