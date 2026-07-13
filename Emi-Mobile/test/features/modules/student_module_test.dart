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
}
