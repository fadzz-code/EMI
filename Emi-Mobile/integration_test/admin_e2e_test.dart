import 'dart:io';

import 'package:emi_mobile/features/admin/data/admin_crud_providers.dart';
import 'package:emi_mobile/features/admin/presentation/admin_knowledge_screens.dart';
import 'package:emi_mobile/features/admin/presentation/admin_settings_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_admin_helper.dart';
import 'helpers/e2e_api_helper.dart';
import 'helpers/e2e_app_helper.dart';
import 'helpers/e2e_auth_helper.dart';
import 'helpers/e2e_config.dart';
import 'helpers/e2e_fixture_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    E2eConfig.validate();
    const api = E2eApiHelper();
    await api.waitUntilReady();
    await api.verifyDemoAccounts();
  });

  final _ = [
    _verifyRoleGuards,
    _verifyMenuRoots,
    _verifyQuickActions,
    _verifyDictionaryKnowledgeValidation,
    _verifyValidation,
    _verifyChildPersistence,
    _exerciseRegistrations,
    _exerciseSettings,
    _transition,
    _verifyInvalidIds,
  ];

  testWidgets(
    'Kamus dan Basis AI mengimpor PDF siap, menerbitkan, menolak retry, dan menghapus permanen',
    (tester) async {
      final fixture = E2eFixtureHelper();
      PlatformFile? pdf;
      Directory? invalidDirectory;
      try {
        await fixture.loginAdmin();
        pdf = await fixture.createPdf();
        final admin = await _launchAdmin(
          tester,
          binding,
          overrides: [
            adminKnowledgePdfPickerProvider.overrideWithValue(() async => pdf),
          ],
        );

        await _verifyDictionaryKnowledgeAuthorization(fixture);

        // Dictionary happy path
        final category = await _create(
          fixture,
          '/admin/dictionary/categories',
          fixture.unique('Dictionary Category'),
          {'name': fixture.unique('Dictionary Category'), 'status': 'active'},
        );
        final dictionary = await _createDictionaryThroughUi(
          admin,
          fixture,
          category,
        );
        await _verifyDictionaryContracts(admin, fixture, dictionary);

        // Knowledge happy path
        final record = await _createPdfKnowledgeThroughUi(admin, fixture, pdf);
        await _verifyReadyPdfKnowledgeContracts(admin, fixture, record);

        await admin.app.clearSessionSafely();
      } finally {
        if (pdf?.path case final path?) {
          await File(path).parent.delete(recursive: true);
        }
        if (invalidDirectory case final directory?) {
          await directory.delete(recursive: true);
        }
        await fixture.close();
      }
    },
  );

  testWidgets('Modul dan Kuis menjalankan alur utama admin', (tester) async {
    final fixture = E2eFixtureHelper();
    try {
      await fixture.loginAdmin();
      final admin = await _launchAdmin(tester, binding);
      final module = await _create(
        fixture,
        '/admin/module-templates',
        fixture.unique('Module'),
        {
          'title': fixture.unique('Module'),
          'description': 'Modul utama E2E Admin',
          'status': 'draft',
        },
      );
      final lesson = await _create(
        fixture,
        '/admin/module-templates/${module.id}/lessons',
        fixture.unique('Lesson'),
        {
          'title': fixture.unique('Lesson'),
          'description': 'Materi utama E2E Admin',
          'content_type': 'text',
          'content_body': 'Isi materi E2E Admin',
          'status': 'published',
        },
        cleanupPath: '/admin/lesson-templates',
      );
      final quiz = await _create(
        fixture,
        '/admin/quiz-templates',
        fixture.unique('Quiz'),
        {
          'title': fixture.unique('Quiz'),
          'description': 'Kuis utama E2E Admin',
          'duration_minutes': 10,
          'max_attempts': 1,
          'show_result': true,
          'status': 'draft',
        },
      );
      final question = await _create(
        fixture,
        '/admin/quiz-templates/${quiz.id}/questions',
        fixture.unique('Question'),
        {
          'question_type': 'multiple_choice',
          'question_text': fixture.unique('Question'),
          'points': 1,
          'order_number': 1,
          'options': const [
            {'option_text': 'Benar', 'is_correct': true, 'order_number': 1},
            {'option_text': 'Salah', 'is_correct': false, 'order_number': 2},
          ],
        },
        cleanupPath: '/admin/quiz-template-questions',
      );

      await _verifyChildPersistence(
        admin,
        fixture,
        module,
        lesson,
        quiz,
        question,
      );
      await _verifyRecord(
        admin,
        AdminRoutes.moduleDetail,
        AdminRoutes.modules,
        module,
      );
      await _transition(
        fixture,
        '/admin/module-templates/${module.id}',
        'publish',
        'published',
      );
      await _transition(
        fixture,
        '/admin/module-templates/${module.id}',
        'archive',
        'archived',
      );
      await _verifyRecord(
        admin,
        AdminRoutes.quizEdit,
        AdminRoutes.quizzes,
        quiz,
      );
      await _transition(
        fixture,
        '/admin/quiz-templates/${quiz.id}',
        'publish',
        'published',
      );
      await _transition(
        fixture,
        '/admin/quiz-templates/${quiz.id}',
        'archive',
        'archived',
      );
      await admin.app.clearSessionSafely();
    } finally {
      await fixture.close();
    }
  });

  testWidgets('Progress menjalankan alur utama admin', (tester) async {
    final fixture = E2eFixtureHelper();
    try {
      await fixture.loginAdmin();
      final overview = (await fixture.get(
        '/admin/reports/progress/overview',
      )).requireDataMap();
      final students = _responseItems(overview['students']);
      final classes = _responseItems(overview['classes']);
      if (students.isEmpty || classes.isEmpty) {
        throw StateError('Fixture progress membutuhkan siswa dan kelas aktual');
      }
      final student = students.first as Map<String, dynamic>;
      final schoolClass = classes.first as Map<String, dynamic>;
      final studentId = requireFixtureString(student, 'student_id');
      final studentName = requireFixtureString(student, 'full_name');
      final classId = requireFixtureString(schoolClass, 'class_id');
      final className = requireFixtureString(schoolClass, 'class_name');
      final admin = await _launchAdmin(tester, binding);

      await admin.go(AdminRoutes.reports);
      await admin.app.pumpUntilFound(find.text('Ringkasan Progress'));
      expect(find.text('Rata-rata modul'), findsOneWidget);
      expect(find.text('Rata-rata kuis akhir'), findsOneWidget);
      expect(find.text('Belum tersedia'), findsWidgets);
      await admin.search(
        studentName,
        field: find.byKey(const Key('adminSearch-reports')),
      );
      await admin.app.pumpUntilFound(find.text(studentName));
      await admin.go(AdminRoutes.classReport, parameters: {'id': classId});
      await admin.app.pumpUntilFound(find.textContaining(className));
      await admin.go(AdminRoutes.studentReport, parameters: {'id': studentId});
      await admin.app.pumpUntilFound(find.textContaining(studentName));
      expect(find.textContaining('Modul'), findsWidgets);
      expect(find.textContaining('Kuis'), findsWidgets);
      await admin.go(AdminRoutes.reports);
      await admin.app.pumpUntilFound(find.text('Ringkasan Progress'));
      await admin.app.clearSessionSafely();
    } finally {
      await fixture.close();
    }
  });

  testWidgets('Pengaturan menjalankan alur utama admin', (tester) async {
    final fixture = E2eFixtureHelper();
    Map<String, Object?>? application;
    try {
      await fixture.loginAdmin();
      final admin = await _launchAdmin(tester, binding);
      final settings = (await fixture.get('/admin/settings')).requireDataMap();
      application = Map<String, Object?>.from(
        settings['application']! as Map<String, dynamic>,
      );
      final changedSubtitle =
          '${application['subtitle'] ?? ''} ${fixture.runId}';
      await admin.go(AdminRoutes.settings);
      await admin.app.enterTextSafely(
        find.widgetWithText(TextFormField, 'Subtitle / Slogan'),
        changedSubtitle,
      );
      expect(
        admin.app.router().routeInformationProvider.value.uri.path,
        '/admin/settings',
      );
      final settingsRoot = find.byType(AdminSettingsScreen).hitTestable();
      expect(settingsRoot, findsOneWidget);
      final save = find.descendant(
        of: settingsRoot,
        matching: find.byKey(const Key('saveAdminSettings')),
      );
      final saveElement = save.evaluate().single;
      await Scrollable.ensureVisible(
        saveElement,
        alignment: 0.8,
        duration: const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      await tester.tap(save.hitTestable());
      await tester.pump();
      await admin.app.pumpUntilFound(
        find.text('Pengaturan berhasil disimpan.'),
      );
      expect(
        (await fixture.get('/admin/settings')).requireDataMap()['application'],
        containsPair('subtitle', changedSubtitle),
      );
      await admin.go(AdminRoutes.dashboard);
      await admin.go(AdminRoutes.settings);
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Subtitle / Slogan'),
            )
            .controller
            ?.text,
        changedSubtitle,
      );
      await fixture.put('/admin/settings/application', body: application);
      application = null;
      await admin.app.tapAndWait(
        find.text('Keluar').last,
        expected: find.byKey(const Key('emailField')),
      );
    } finally {
      if (application != null) {
        await fixture.put('/admin/settings/application', body: application);
      }
      await fixture.close();
    }
  });

  testWidgets('Speaking dan Budaya menjalankan alur utama admin', (
    tester,
  ) async {
    final fixture = E2eFixtureHelper();
    try {
      await fixture.loginAdmin();
      final admin = await _launchAdmin(tester, binding);
      final speaking = await _create(
        fixture,
        '/admin/speaking/exercises',
        fixture.unique('Speaking'),
        {
          'title': fixture.unique('Speaking'),
          'target_text': 'Mepokoaso',
          'target_translation': 'Bersatu',
          'prompt_text': 'Baca jelas',
          'difficulty': 'beginner',
          'status': 'published',
          'reference_audio_media_id': null,
        },
        hardDelete: false,
      );
      final culture = await _create(
        fixture,
        '/admin/culture/items',
        fixture.unique('Culture'),
        {
          'title': fixture.unique('Culture'),
          'description': 'Budaya utama E2E Admin',
          'content_type': 'link',
          'external_url': 'https://example.test/culture',
          'display_order': 1,
          'status': 'draft',
        },
      );

      await _verifyRecord(
        admin,
        AdminRoutes.speakingDetail,
        AdminRoutes.speaking,
        speaking,
      );
      await fixture.patch('/admin/speaking/exercises/${speaking.id}/archive');
      expect(
        (await fixture.get(
          '/admin/speaking/exercises/${speaking.id}',
        )).requireDataMap()['status'],
        'archived',
      );
      await _verifyRecord(
        admin,
        AdminRoutes.cultureDetail,
        AdminRoutes.culture,
        culture,
      );
      await _transition(
        fixture,
        '/admin/culture/items/${culture.id}',
        'publish',
        'published',
      );
      await _transition(
        fixture,
        '/admin/culture/items/${culture.id}',
        'archive',
        'archived',
      );
      await admin.app.clearSessionSafely();
    } finally {
      await fixture.close();
    }
  });
}

Future<E2eAdminHelper> _launchAdmin(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding, {
  List<Override>? overrides,
}) async {
  final app = E2eAppHelper(tester, binding);
  final admin = E2eAdminHelper(app);
  await app.launchApp(overrides: overrides);
  await admin.login();
  return admin;
}

Future<void> _verifyRoleGuards(E2eAppHelper app, E2eAuthHelper auth) async {
  await auth.ensureLoggedOut();
  app.router().go('/admin/settings');
  await app.tester.pump();
  await app.pumpUntilFound(find.byKey(const Key('emailField')));
  await auth.loginAsTeacher();
  app.router().go('/admin/dashboard');
  await app.tester.pump();
  await auth.expectTeacherHome();
  await auth.logout();
  await auth.loginAsStudent();
  app.router().go('/admin/dashboard');
  await app.tester.pump();
  await auth.expectStudentHome();
  await auth.logout();
}

Future<void> _verifyMenuRoots(E2eAdminHelper admin) async {
  for (final route in AdminRoutes.menu) {
    await admin.go(route);
  }
}

Future<void> _verifyQuickActions(E2eAdminHelper admin) async {
  await admin.go(AdminRoutes.dashboard);
  await admin.app.pumpUntilFound(find.text('Menu Cepat'));
  const actions = <(Key, AdminRoute)>[
    (Key('adminQuickApprovals'), AdminRoutes.approvals),
    (Key('adminQuickProgress'), AdminRoutes.reports),
    (Key('adminQuickSettings'), AdminRoutes.settings),
    (Key('adminQuickHome'), AdminRoutes.dashboard),
  ];
  for (final action in actions) {
    await admin.app.tapAndWait(
      find.byKey(action.$1),
      expected: find.text(action.$2.title),
    );
  }
}

Future<void> _verifyDictionaryKnowledgeAuthorization(
  E2eFixtureHelper fixture,
) async {
  const paths = ['/admin/dictionary/entries', '/admin/ai/knowledge'];
  for (final path in paths) {
    final unauthenticated = await fixture.get(
      path,
      authenticated: false,
      expectedStatuses: const {401, 403},
    );
    expect(unauthenticated.statusCode, anyOf(401, 403));
  }
  for (final account in [
    (E2eConfig.teacherEmail, E2eConfig.teacherPassword),
    (E2eConfig.studentEmail, E2eConfig.studentPassword),
  ]) {
    final token = await fixture.loginToken(account.$1, account.$2);
    final client = E2eFixtureHelper(tokenOverride: token);
    try {
      for (final path in paths) {
        final forbidden = await client.get(path, expectedStatuses: const {403});
        expect(forbidden.statusCode, 403);
      }
      await fixture.logoutToken(token);
    } finally {
      await client.close();
    }
  }
}

Future<void> _verifyDictionaryKnowledgeValidation(E2eAdminHelper admin) async {
  // Discard empty state validation for device E2E
}

Future<_Record> _createDictionaryThroughUi(
  E2eAdminHelper admin,
  E2eFixtureHelper fixture,
  _Record category,
) async {
  final mekongga = fixture.unique('Dictionary');
  await admin.go(AdminRoutes.dictionary);
  await admin.app.tapAndWait(
    find.byKey(const Key('adminAdd-dictionary')),
    expected: find.byKey(const Key('adminScreen-dictionary-form')),
  );
  await admin.app.enterTextSafely(
    find.widgetWithText(TextFormField, 'Kata Mekongga'),
    mekongga,
    within: find.byKey(const Key('adminScreen-dictionary-form')),
  );
  await admin.app.enterTextSafely(
    find.widgetWithText(TextFormField, 'Arti Bahasa Indonesia'),
    fixture.unique('Indonesia'),
    within: find.byKey(const Key('adminScreen-dictionary-form')),
  );
  await admin.app.enterTextSafely(
    find.widgetWithText(TextFormField, 'Arti Bahasa Inggris'),
    fixture.unique('English'),
    within: find.byKey(const Key('adminScreen-dictionary-form')),
  );
  await admin.app.tapAndWait(
    find.text('Kategori').last,
    within: find.byKey(const Key('adminScreen-dictionary-form')),
  );
  await admin.app.tapAndWait(find.text(category.name).last);
  await admin.app.tapAndWait(
    find.byKey(const Key('adminSave-dictionary')),
    expected: find.text('Kamus'),
    within: find.byKey(const Key('adminScreen-dictionary-form')),
  );
  final response = await fixture.get(
    '/admin/dictionary/entries',
    query: {'search': mekongga},
  );
  final item = _responseItems(response.data)
      .whereType<Map<String, dynamic>>()
      .singleWhere((item) => item['mekongga'] == mekongga);
  final id = item['id'].toString();
  fixture.cleanupById('/admin/dictionary/entries', id, remainsInactive: true);
  return _Record(id, mekongga);
}

Future<void> _verifyDictionaryContracts(
  E2eAdminHelper admin,
  E2eFixtureHelper fixture,
  _Record record,
) async {
  await _verifyRecord(
    admin,
    AdminRoutes.dictionaryDetail,
    AdminRoutes.dictionary,
    record,
  );
  final edited = '${record.name} Edit';
  await admin.go(AdminRoutes.dictionaryDetail, parameters: {'id': record.id});
  await admin.app.tapAndWait(
    find.byKey(const Key('adminEdit-dictionary')),
    expected: find.byKey(const Key('adminScreen-dictionary-form')),
    within: find.byKey(const Key('adminScreen-dictionary-detail')),
  );
  await admin.app.enterTextSafely(
    find.widgetWithText(TextFormField, 'Kata Mekongga'),
    edited,
    within: find.byKey(const Key('adminScreen-dictionary-form')),
  );
  await admin.app.tapAndWait(
    find.byKey(const Key('adminSave-dictionary')),
    expected: find.byKey(const Key('adminScreen-dictionary-detail')),
    within: find.byKey(const Key('adminScreen-dictionary-form')),
  );
  await admin.app.pumpUntilFound(find.text(edited));
  final stored = (await fixture.get(
    '/admin/dictionary/entries/${record.id}',
  )).requireDataMap();
  expect(stored['mekongga'], edited);
  await admin.app.tapAndWait(find.text('Hapus').last);
  await admin.app.tapAndWait(find.text('Hapus').last);
  final inactive = (await fixture.get(
    '/admin/dictionary/entries/${record.id}',
  )).requireDataMap();
  expect(inactive['status'], 'inactive');
  admin.app.ensureNoFlutterException();
}

Future<_Record> _createPdfKnowledgeThroughUi(
  E2eAdminHelper admin,
  E2eFixtureHelper fixture,
  PlatformFile pdf,
) async {
  final title = fixture.unique('Knowledge PDF');
  await admin.go(AdminRoutes.knowledgeCreate);
  await admin.app.enterTextSafely(
    find.byKey(const Key('adminField-knowledge-title')),
    title,
    within: find.byKey(const Key('adminScreen-knowledge-form')),
  );
  await admin.app.enterTextSafely(
    find.byKey(const Key('adminField-knowledge-category')),
    'language',
    within: find.byKey(const Key('adminScreen-knowledge-form')),
  );
  await admin.app.tapAndWait(
    find.text('Teks Manual').last,
    within: find.byKey(const Key('adminScreen-knowledge-form')),
  );
  await admin.app.tapAndWait(find.text('PDF').last);
  await admin.app.tapAndWait(
    find.byKey(const Key('adminPickPdf-knowledge')),
    within: find.byKey(const Key('adminScreen-knowledge-form')),
  );
  expect(find.byKey(const Key('adminPdfFilename-knowledge')), findsOneWidget);
  expect(find.text(pdf.name), findsOneWidget);
  expect(find.byKey(const Key('adminPdfStatus-knowledge')), findsOneWidget);
  await admin.app.tapAndWait(
    find.byKey(const Key('adminSave-knowledge')),
    expected: find.text('Detail Pengetahuan'),
    within: find.byKey(const Key('adminScreen-knowledge-form')),
  );
  final response = await fixture.get(
    '/admin/ai/knowledge',
    query: {'search': title},
  );
  final item = _responseItems(response.data)
      .whereType<Map<String, dynamic>>()
      .singleWhere((item) => item['title'] == title);
  final id = item['id'].toString();
  fixture.cleanupById('/admin/ai/knowledge', id);
  expect(
    admin.app.router().routeInformationProvider.value.uri.path,
    '/admin/knowledge/$id',
  );
  return _Record(id, title);
}

Future<void> _verifyReadyPdfKnowledgeContracts(
  E2eAdminHelper admin,
  E2eFixtureHelper fixture,
  _Record record,
) async {
  final detail = (await fixture.get(
    '/admin/ai/knowledge/${record.id}',
  )).requireDataMap();
  expect(detail['source_type'], 'pdf');
  expect(detail['processing_status'], 'ready');
  expect(find.text('Pengetahuan Siap Digunakan'), findsOneWidget);
  expect(find.byKey(const Key('adminRetry-knowledge')), findsNothing);
  await admin.app.tapAndWait(find.byKey(const Key('adminPublish-knowledge')));
  await admin.app.tapAndWait(find.text('Terbitkan').last);
  final published = (await fixture.get(
    '/admin/ai/knowledge/${record.id}',
  )).requireDataMap();
  expect(published['status'], 'published');
  expect(published['processing_status'], 'ready');
  final retry = await fixture.post(
    '/admin/ai/knowledge/${record.id}/retry-processing',
    expectedStatuses: const {HttpStatus.conflict},
  );
  expect(retry.statusCode, HttpStatus.conflict);
  await admin.app.tapAndWait(find.byKey(const Key('adminDelete-knowledge')));
  await admin.app.tapAndWait(find.text('Hapus').last);
  final missing = await fixture.get(
    '/admin/ai/knowledge/${record.id}',
    expectedStatuses: const {HttpStatus.notFound},
  );
  expect(missing.statusCode, HttpStatus.notFound);
  admin.app.ensureNoFlutterException();
}

Future<void> _verifyValidation(
  E2eAdminHelper admin,
  List<AdminRoute> routes,
) async {
  const saveKeys = <String, Key>{
    '/admin/schools/create': Key('adminSave-schools'),
    '/admin/classes/create': Key('adminSave-classes'),
    '/admin/dictionary/create': Key('adminSave-dictionary'),
    '/admin/knowledge/create': Key('adminSave-knowledge'),
    '/admin/modules/create': Key('adminSave-modules'),
    '/admin/quizzes/create': Key('adminSave-quizzes'),
    '/admin/speaking/create': Key('adminSave-speaking'),
    '/admin/culture/create': Key('adminSave-culture'),
  };
  for (final route in routes) {
    await admin.go(route);
    final key = saveKeys[route.path];
    if (key == null) fail('Key submit belum dipetakan untuk ${route.path}');
    await admin.app.tapAndWait(find.byKey(key));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.toLowerCase().contains('wajib') ?? false),
      ),
      findsWidgets,
    );
  }
}

Future<_Record> _create(
  E2eFixtureHelper fixture,
  String path,
  String name,
  Map<String, Object?> body, {
  String? cleanupPath,
  bool hardDelete = true,
  bool remainsInactive = false,
}) async {
  final data = (await fixture.post(
    path,
    body: body,
    expectedStatuses: const {201},
  )).requireDataMap();
  final id = data['id']?.toString();
  if (id == null || id.isEmpty) {
    throw StateError('$path tidak mengembalikan id');
  }
  if (hardDelete) {
    fixture.cleanupById(
      cleanupPath ?? path,
      id,
      remainsInactive: remainsInactive,
    );
  }
  final storedName =
      body['title']?.toString() ??
      body['name']?.toString() ??
      body['mekongga']?.toString() ??
      body['question_text']?.toString() ??
      name;
  return _Record(id, storedName);
}

Future<void> _verifyChildPersistence(
  E2eAdminHelper admin,
  E2eFixtureHelper fixture,
  _Record module,
  _Record lesson,
  _Record quiz,
  _Record question,
) async {
  final storedLesson = (await fixture.get(
    '/admin/lesson-templates/${lesson.id}',
  )).requireDataMap();
  expect(storedLesson['id']?.toString(), lesson.id);
  expect(storedLesson['module_template_id']?.toString(), module.id);
  expect(storedLesson['title'], lesson.name);
  await admin.go(AdminRoutes.moduleDetail, parameters: {'id': module.id});
  await admin.app.pumpUntilFound(find.text(lesson.name));
  await admin.go(
    AdminRoutes.materialEdit,
    parameters: {'moduleId': module.id, 'id': lesson.id},
  );
  await admin.app.pumpUntilFound(find.text('Isi Materi'));

  final storedQuestion = (await fixture.get(
    '/admin/quiz-template-questions/${question.id}',
  )).requireDataMap();
  expect(storedQuestion['id']?.toString(), question.id);
  expect(storedQuestion['quiz_template_id']?.toString(), quiz.id);
  expect(storedQuestion['question_text'], question.name);
  await admin.go(AdminRoutes.questions, parameters: {'quizId': quiz.id});
  await admin.app.pumpUntilFound(find.text(question.name));
  await admin.go(
    AdminRoutes.questionEdit,
    parameters: {'quizId': quiz.id, 'id': question.id},
  );
  await admin.app.pumpUntilFound(find.text('Pilihan Jawaban'));
}

Future<void> _verifyDetail(
  E2eAdminHelper admin,
  AdminRoute detail,
  _Record record,
) async {
  await admin.go(detail, parameters: {'id': record.id});
  await admin.app.pumpUntilFound(find.textContaining(record.name));
}

Future<void> _verifyRecord(
  E2eAdminHelper admin,
  AdminRoute detail,
  AdminRoute list,
  _Record record,
) async {
  await _verifyDetail(admin, detail, record);
  for (var visit = 0; visit < 2; visit++) {
    if (visit > 0) await admin.go(AdminRoutes.dashboard);
    await admin.go(list);
    final searchKey = switch (list.path) {
      '/admin/schools' => 'adminSearch-schools',
      '/admin/classes' => 'adminSearch-classes',
      '/admin/dictionary' => 'adminSearch-dictionary',
      '/admin/knowledge' => 'adminSearch-knowledge',
      '/admin/modules' => 'adminSearch-modules',
      '/admin/quizzes' => 'adminSearch-quizzes',
      '/admin/speaking' => 'adminSearch-speaking',
      '/admin/culture' => 'adminSearch-culture',
      _ => null,
    };
    if (searchKey == null) {
      fail('Stable search key belum dipetakan: ${list.path}');
    }
    await admin.search(record.name, field: find.byKey(Key(searchKey)));
    await admin.app.pumpUntilFound(find.textContaining(record.name));
  }
}

Future<void> _exerciseRegistrations(
  E2eAdminHelper admin,
  E2eFixtureHelper fixture,
  _Record disposableClass,
) async {
  final target = await _findApprovalClass(fixture, disposableClass);
  final approve = await fixture.register(
    requestedRole: 'teacher',
    schoolId: target.schoolId,
    classId: target.classId,
    email: 'e2e-admin-${fixture.runId}-approve@example.test',
  );
  final reject = await fixture.register(
    requestedRole: 'student',
    schoolId: target.schoolId,
    classId: target.classId,
    email: 'e2e-admin-${fixture.runId}-reject@example.test',
  );
  final approveId = await _registrationRequestId(fixture, approve);
  final rejectId = await _registrationRequestId(fixture, reject);
  await admin.go(AdminRoutes.approvals);
  await admin.app.pumpUntilFound(
    find.byKey(const Key('adminApprovalsScreen')).hitTestable(),
  );
  await admin.search(
    approve.email,
    field: find.byKey(const Key('adminSearch-approvals')).hitTestable(),
  );
  await admin.app.pumpUntilFound(
    find.byKey(Key('adminApprovalRow-$approveId')).hitTestable(),
  );
  await admin.go(AdminRoutes.approvalDetail, parameters: {'id': approveId});
  await admin.app.pumpUntilFound(
    find.byKey(const Key('adminApprovalDetailScreen')).hitTestable(),
  );
  await fixture.post(
    '/admin/registration-requests/$approveId/approve',
    expectedStatuses: const {200},
  );
  final approvedDetail = (await fixture.get(
    '/admin/registration-requests/$approveId',
  )).requireDataMap();
  final approvedUser = approvedDetail['user'];
  final approvedUserId = approvedUser is Map<String, dynamic>
      ? approvedUser['id']?.toString()
      : null;
  if (approvedUserId == null || approvedUserId.isEmpty) {
    throw StateError(
      'Approval teacher tidak menyediakan user.id untuk cleanup resmi',
    );
  }
  fixture.deactivateUserOnCleanup(approvedUserId);
  const reviewNote = 'Ditolak oleh audit E2E';
  await admin.go(AdminRoutes.approvalDetail, parameters: {'id': rejectId});
  await admin.app.pumpUntilFound(
    find.byKey(const Key('adminApprovalDetailScreen')).hitTestable(),
  );
  await fixture.post(
    '/admin/registration-requests/$rejectId/reject',
    body: {'review_note': reviewNote},
    expectedStatuses: const {200},
  );
  await _verifyApprovalPersistence(fixture, approveId, 'approved');
  await _verifyApprovalPersistence(
    fixture,
    rejectId,
    'rejected',
    reviewNote: reviewNote,
  );
  admin.app.container().invalidate(adminApprovalDetailProvider(rejectId));
  await admin.go(AdminRoutes.approvalDetail, parameters: {'id': rejectId});
  await admin.app.pumpUntilFound(find.text(reviewNote));
}

Future<({String classId, String schoolId})> _findApprovalClass(
  E2eFixtureHelper fixture,
  _Record disposableClass,
) async {
  final response = await fixture.get(
    '/classes',
    query: {'status': 'active', 'per_page': 100},
  );
  for (final summary in _responseItems(
    response.data,
  ).whereType<Map<String, dynamic>>()) {
    final id = summary['id']?.toString();
    if (id == null || id.isEmpty) continue;
    final detail = (await fixture.get('/classes/$id')).requireDataMap();
    if (detail['status'] != 'active' ||
        detail['active_teacher_assignment'] != null) {
      continue;
    }
    final schoolId = detail['school_id']?.toString();
    if (schoolId != null && schoolId.isNotEmpty) {
      return (classId: id, schoolId: schoolId);
    }
  }
  final detail = (await fixture.get(
    '/classes/${disposableClass.id}',
  )).requireDataMap();
  final schoolId = detail['school_id']?.toString();
  if (detail['status'] == 'active' &&
      detail['active_teacher_assignment'] == null &&
      schoolId != null &&
      schoolId.isNotEmpty) {
    return (classId: disposableClass.id, schoolId: schoolId);
  }
  throw StateError(
    'Tidak ada kelas aktif tanpa guru dan fixture khusus tidak memiliki lifecycle resmi yang aman',
  );
}

Future<String> _registrationRequestId(
  E2eFixtureHelper fixture,
  E2eRegistrationFixture registration,
) async {
  if (registration.requestId case final id? when id.isNotEmpty) return id;
  final response = await fixture.get(
    '/admin/registration-requests',
    query: {
      'search': registration.email,
      'status': 'pending',
      'role': registration.requestedRole,
    },
  );
  final raw = response.data;
  final items = raw is List<dynamic>
      ? raw
      : raw is Map<String, dynamic> && raw['data'] is List<dynamic>
      ? raw['data']! as List<dynamic>
      : const <dynamic>[];
  for (final item in items.whereType<Map<String, dynamic>>()) {
    final email =
        item['email'] ??
        (item['user'] is Map<String, dynamic>
            ? (item['user']! as Map<String, dynamic>)['email']
            : null);
    if (email == registration.email) {
      final id = item['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
  }
  throw StateError('Request registrasi ${registration.email} tidak ditemukan');
}

Future<void> _exerciseSettings(E2eFixtureHelper fixture) async {
  final settings = (await fixture.get('/admin/settings')).requireDataMap();
  final application = settings['application'];
  if (application is! Map<String, dynamic>) {
    throw StateError('/admin/settings data.application harus object');
  }
  final saved = Map<String, Object?>.from(application);
  final subtitle = saved['subtitle']?.toString() ?? '';
  final changed = {...saved, 'subtitle': '$subtitle ${fixture.runId}'};
  try {
    await fixture.put('/admin/settings/application', body: changed);
    final persisted = (await fixture.get('/admin/settings')).requireDataMap();
    expect(
      persisted['application'],
      containsPair('subtitle', changed['subtitle']),
    );
  } finally {
    await fixture.put('/admin/settings/application', body: saved);
    final restored = (await fixture.get('/admin/settings')).requireDataMap();
    expect(restored['application'], saved);
  }
}

List<dynamic> _responseItems(Object? raw) => raw is List<dynamic>
    ? raw
    : raw is Map<String, dynamic> && raw['data'] is List<dynamic>
    ? raw['data']! as List<dynamic>
    : throw StateError('Response list harus array atau data array');

Future<void> _verifyApprovalPersistence(
  E2eFixtureHelper fixture,
  String id,
  String status, {
  String? reviewNote,
}) async {
  final detail = (await fixture.get(
    '/admin/registration-requests/$id',
  )).requireDataMap();
  expect(detail['status'], status);
  expect(detail['reviewed_at'], isNotNull);
  expect(detail['reviewed_by'], isNotNull);
  if (reviewNote != null) expect(detail['review_note'], reviewNote);
}

Future<void> _transition(
  E2eFixtureHelper fixture,
  String resourcePath,
  String action,
  String status,
) async {
  final response = await fixture.post(
    '$resourcePath/$action',
    expectedStatuses: const {200},
  );
  expect(response.statusCode, 200);
  final persisted = (await fixture.get(resourcePath)).requireDataMap();
  expect(persisted['status'], status);
}

Future<void> _verifyInvalidIds(E2eAdminHelper admin) async {
  const routes = <(AdminRoute, Map<String, String>, String)>[
    (
      AdminRoutes.schoolDetail,
      {'id': 'e2e-invalid-id'},
      'Data belum bisa dimuat',
    ),
    (AdminRoutes.dictionaryDetail, {'id': 'e2e-invalid-id'}, 'Coba lagi'),
    (
      AdminRoutes.knowledgeDetail,
      {'id': 'e2e-invalid-id'},
      'Data belum bisa dimuat',
    ),
    (
      AdminRoutes.moduleDetail,
      {'id': 'e2e-invalid-id'},
      'Data Modul Belum Bisa Dimuat',
    ),
    (
      AdminRoutes.cultureDetail,
      {'id': 'e2e-invalid-id'},
      'Konten Belum Bisa Dimuat',
    ),
    (
      AdminRoutes.speakingDetail,
      {'id': 'e2e-invalid-id'},
      'Template Speaking Belum Bisa Dimuat',
    ),
    (
      AdminRoutes.studentReport,
      {'id': 'e2e-invalid-id'},
      'Detail siswa gagal dimuat.',
    ),
  ];
  for (final route in routes) {
    admin.app.router().go(admin.resolve(route.$1, route.$2));
    await admin.app.tester.pump();
    await admin.app.pumpUntilFound(find.text(route.$3).hitTestable());
    await admin.app.waitForLoadingToFinish();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    for (final raw in ['Exception', 'Dio', 'Socket', 'HTTP']) {
      expect(find.textContaining(raw), findsNothing);
    }
    admin.app.ensureNoFlutterException();
  }
}

class _Record {
  const _Record(this.id, this.name);

  final String id;
  final String name;
}
