import 'package:emi_mobile/features/admin/data/admin_progress_models.dart';
import 'package:emi_mobile/features/admin/presentation/admin_progress_detail_screens.dart';
import 'package:emi_mobile/features/admin/presentation/admin_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {double width = 400}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 900),
        textScaler: const TextScaler.linear(1.2),
      ),
      child: Scaffold(
        body: SizedBox(width: width, child: child),
      ),
    ),
  );
  final json = <String, dynamic>{
    'student_id': 's1',
    'full_name': 'Ani',
    'email': '',
    'student_status': 'active',
    'learning_status': 'in_progress',
    'school': {'name': 'Sekolah A'},
    'class': {'name': 'Kelas 1'},
    'completed_modules': 2,
    'published_modules': 4,
    'overall_learning_progress_percent': 50,
    'average_best_quiz_score_percent': 80,
    'last_learning_activity_at': '2026-07-01',
  };
  test(
    'filters sends independent pages',
    () => expect(
      const AdminProgressFilters().query(studentPage: 2, classPage: 3),
      {'student_page': 2, 'class_page': 3},
    ),
  );
  test(
    'filters trims search',
    () => expect(
      const AdminProgressFilters(
        search: ' ani ',
      ).query(studentPage: 1, classPage: 1)['search'],
      'ani',
    ),
  );
  test(
    'filters sends school',
    () => expect(
      const AdminProgressFilters(
        schoolId: 'x',
      ).query(studentPage: 1, classPage: 1)['school_id'],
      'x',
    ),
  );
  test(
    'filters sends class',
    () => expect(
      const AdminProgressFilters(
        classId: 'x',
      ).query(studentPage: 1, classPage: 1)['class_id'],
      'x',
    ),
  );
  test(
    'filters maps status',
    () => expect(
      const AdminProgressFilters(
        learningStatus: 'completed',
      ).query(studentPage: 1, classPage: 1)['learning_status'],
      'completed',
    ),
  );
  test(
    'student id',
    () => expect(AdminProgressStudent.fromJson(json).id, 's1'),
  );
  test(
    'student name',
    () => expect(AdminProgressStudent.fromJson(json).fullName, 'Ani'),
  );
  test(
    'student email fallback source stays empty',
    () => expect(AdminProgressStudent.fromJson(json).email, isEmpty),
  );
  test(
    'student status',
    () => expect(AdminProgressStudent.fromJson(json).studentStatus, 'active'),
  );
  test(
    'learning status',
    () => expect(
      AdminProgressStudent.fromJson(json).learningStatus,
      'in_progress',
    ),
  );
  test(
    'nested school',
    () => expect(AdminProgressStudent.fromJson(json).schoolName, 'Sekolah A'),
  );
  test(
    'nested class',
    () => expect(AdminProgressStudent.fromJson(json).className, 'Kelas 1'),
  );
  test(
    'module counts',
    () => expect(AdminProgressStudent.fromJson(json).completedModules, 2),
  );
  test(
    'module percent',
    () => expect(
      AdminProgressStudent.fromJson(json).overallLearningProgressPercent,
      50,
    ),
  );
  test(
    'quiz percent',
    () => expect(
      AdminProgressStudent.fromJson(json).averageBestQuizScorePercent,
      80,
    ),
  );
  test(
    'activity',
    () => expect(
      AdminProgressStudent.fromJson(json).lastActivityAt,
      '2026-07-01',
    ),
  );
  test(
    'meta parses pages',
    () => expect(
      AdminProgressMeta.fromJson({
        'current_page': 2,
        'last_page': 4,
        'total': 9,
      }).lastPage,
      4,
    ),
  );
  test(
    'summary parses students',
    () => expect(
      AdminProgressSummary.fromJson({'active_students': 5}).activeStudents,
      5,
    ),
  );
  test(
    'capability false',
    () => expect(
      AdminProgressOverview.fromJson({
        'summary': {},
        'students': {},
        'classes': {},
        'capabilities': {'speaking_reports': false},
      }).speakingReports,
      isFalse,
    ),
  );
  test(
    'class exact id',
    () => expect(AdminProgressClass.fromJson({'class_id': 'c1'}).id, 'c1'),
  );
  test(
    'class score',
    () => expect(
      AdminProgressClass.fromJson({
        'average_quiz_score_percent': 77,
      }).averageQuizScorePercent,
      77,
    ),
  );
  testWidgets('overview narrow has four cards in two rows', (tester) async {
    await tester.pumpWidget(
      host(
        ProgressOverviewSummary(
          AdminProgressSummary.fromJson({
            'active_students': 5,
            'average_module_progress_percent': 50,
            'average_best_final_quiz_score_percent': 80,
          }),
          speakingReports: false,
        ),
      ),
    );
    expect(find.byType(ProgressMetricTile), findsNWidgets(4));
    expect(find.text('Rata-rata Speaking'), findsOneWidget);
    expect(find.text('Belum tersedia'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    final first = tester.getTopLeft(find.byType(ProgressMetricTile).at(0));
    final third = tester.getTopLeft(find.byType(ProgressMetricTile).at(2));
    expect(third.dy, greaterThan(first.dy));
    expect(tester.takeException(), isNull);
  });
  testWidgets('overview wide has one row', (tester) async {
    await tester.pumpWidget(
      host(
        ProgressOverviewSummary(
          AdminProgressSummary.fromJson({}),
          speakingReports: true,
        ),
        width: 900,
      ),
    );
    final tiles = find.byType(ProgressMetricTile);
    expect(
      tester.getTopLeft(tiles.at(0)).dy,
      tester.getTopLeft(tiles.at(3)).dy,
    );
    expect(find.text('-'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('compact student and class items show icons', (tester) async {
    await tester.pumpWidget(
      host(
        ListView(
          children: [
            ProgressStudentItem(
              student: AdminProgressStudent.fromJson(json),
              onTap: () {},
            ),
            ProgressClassItem(
              item: AdminProgressClass.fromJson({
                'class_id': 'c1',
                'class_name': 'Kelas 1',
                'school_name': 'Sekolah A',
              }),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('detail grids contain required metrics', (tester) async {
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: Column(
            children: [
              StudentLearningMetricGrid(
                progress: AdminProgressStudent.fromJson(json),
              ),
              StudentQuizMetricGrid(summary: AdminQuizSummary.fromJson({})),
              ClassMetricGrid(
                summary: AdminClassProgressSummary.fromJson({}),
                speakingReports: false,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(ProgressMetricTile), findsNWidgets(14));
    expect(find.text('Progress modul'), findsOneWidget);
    expect(find.text('Rata-rata nilai terbaik'), findsOneWidget);
    expect(find.text('Rata-rata Speaking'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test(
    'quiz history meta',
    () => expect(
      AdminStudentProgressDetail.fromJson({
        'student': json,
        'progress': {},
        'quizzes': {
          'data': [],
          'meta': {'last_page': 3},
        },
        'quiz_summary': {},
        'capabilities': {},
      }).quizzes.meta.lastPage,
      3,
    ),
  );
}
