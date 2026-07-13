import 'package:emi_mobile/features/modules/data/student_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps module page json', () {
    final page = StudentModulePage.fromJson({
      'data': [
        {
          'id': 'module-1',
          'title': 'Aksara Mekongga',
          'description': 'Belajar dasar',
          'status': 'published',
          'sort_order': 1,
          'progress': {
            'status': 'in_progress',
            'progress_percent': 50,
            'completed_lessons': 2,
            'total_lessons': 4,
          },
        },
      ],
      'meta': {'current_page': 1, 'last_page': 2, 'total': 1},
    });

    expect(page.items.single.title, 'Aksara Mekongga');
    expect(page.items.single.progress.status, 'in_progress');
    expect(page.items.single.progress.progressPercent, 50);
    expect(page.hasNextPage, true);
  });

  test('maps module detail lessons json', () {
    final module = StudentModule.fromJson({
      'id': 'module-1',
      'title': 'Sapaan',
      'status': 'published',
      'sort_order': 1,
      'progress': {'status': 'not_started', 'progress_percent': 0},
      'lessons': [
        {
          'id': 'lesson-1',
          'class_module_id': 'module-1',
          'title': 'Pengenalan Sapaan',
          'description': 'Sapaan dasar',
          'content_type': 'text',
          'content_body': 'Mombesara',
          'sort_order': 1,
          'status': 'published',
          'media': {
            'id': 'media-1',
            'mime_type': 'image/png',
            'visibility': 'public',
          },
        },
      ],
    });

    expect(module.lessons.single.title, 'Pengenalan Sapaan');
    expect(module.lessons.single.hasTextContent, true);
    expect(module.lessons.single.media?.isImage, true);
  });

  test('maps lesson progress json', () {
    final progress = LessonProgress.fromJson({
      'id': 'progress-1',
      'class_lesson_id': 'lesson-1',
      'status': 'completed',
      'progress_percent': 100,
    });

    expect(progress.status, 'completed');
    expect(progress.progressPercent, 100);
  });
}
