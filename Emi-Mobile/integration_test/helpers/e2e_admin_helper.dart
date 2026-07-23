import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_app_helper.dart';
import 'e2e_auth_helper.dart';

class AdminRoute {
  const AdminRoute(this.path, this.title);

  final String path;
  final String title;
}

abstract final class AdminRoutes {
  static const dashboard = AdminRoute('/admin/dashboard', 'Beranda Admin');
  static const approvals = AdminRoute('/admin/approvals', 'Persetujuan Akun');
  static const approvalDetail = AdminRoute(
    '/admin/approvals/:id',
    'Detail Pemohon',
  );
  static const users = AdminRoute('/admin/users', 'Guru dan Siswa');
  static const userDetail = AdminRoute('/admin/users/:id', 'Detail Pengguna');
  static const schools = AdminRoute('/admin/schools', 'Sekolah');
  static const schoolCreate = AdminRoute(
    '/admin/schools/create',
    'Tambah Sekolah',
  );
  static const schoolEdit = AdminRoute(
    '/admin/schools/:id/edit',
    'Edit Sekolah',
  );
  static const schoolDetail = AdminRoute(
    '/admin/schools/:id',
    'Detail Sekolah',
  );
  static const classes = AdminRoute('/admin/classes', 'Kelas');
  static const classCreate = AdminRoute(
    '/admin/classes/create',
    'Tambah Kelas',
  );
  static const classEdit = AdminRoute('/admin/classes/:id/edit', 'Edit Kelas');
  static const classDetail = AdminRoute('/admin/classes/:id', 'Detail Kelas');
  static const dictionary = AdminRoute('/admin/dictionary', 'Kamus');
  static const dictionaryCreate = AdminRoute(
    '/admin/dictionary/create',
    'Tambah Kosakata',
  );
  static const dictionaryCategories = AdminRoute(
    '/admin/dictionary/categories',
    'Kategori Kamus',
  );
  static const dictionaryImport = AdminRoute(
    '/admin/dictionary/import',
    'Import Kamus',
  );
  static const dictionaryEdit = AdminRoute(
    '/admin/dictionary/:id/edit',
    'Edit Kosakata',
  );
  static const dictionaryDetail = AdminRoute(
    '/admin/dictionary/:id',
    'Detail Kosakata',
  );
  static const knowledge = AdminRoute(
    '/admin/knowledge',
    'Pengetahuan Basis AI',
  );
  static const knowledgeCreate = AdminRoute(
    '/admin/knowledge/create',
    'Tambah Pengetahuan',
  );
  static const knowledgeEdit = AdminRoute(
    '/admin/knowledge/:id/edit',
    'Edit Pengetahuan Basis AI',
  );
  static const knowledgeDetail = AdminRoute(
    '/admin/knowledge/:id',
    'Detail Knowledge Base',
  );
  static const modules = AdminRoute('/admin/modules', 'Modul Pembelajaran');
  static const moduleCreate = AdminRoute(
    '/admin/modules/create',
    'Tambah Modul',
  );
  static const moduleEdit = AdminRoute('/admin/modules/:id/edit', 'Edit Modul');
  static const materialCreate = AdminRoute(
    '/admin/modules/:moduleId/materials/create',
    'Tambah Materi',
  );
  static const materialEdit = AdminRoute(
    '/admin/modules/:moduleId/materials/:id/edit',
    'Edit Materi',
  );
  static const moduleDetail = AdminRoute('/admin/modules/:id', 'Detail Modul');
  static const quizzes = AdminRoute('/admin/quizzes', 'Template Kuis');
  static const quizCreate = AdminRoute(
    '/admin/quizzes/create',
    'Tambah Template Kuis',
  );
  static const quizEdit = AdminRoute(
    '/admin/quizzes/:id',
    'Edit Template Kuis',
  );
  static const questions = AdminRoute(
    '/admin/quizzes/:quizId/questions',
    'Pertanyaan Kuis',
  );
  static const questionCreate = AdminRoute(
    '/admin/quizzes/:quizId/questions/create',
    'Tambah Pertanyaan',
  );
  static const questionEdit = AdminRoute(
    '/admin/quizzes/:quizId/questions/:id',
    'Edit Pertanyaan',
  );
  static const culture = AdminRoute('/admin/culture', 'Budaya Mekongga');
  static const cultureCreate = AdminRoute(
    '/admin/culture/create',
    'Tambah Budaya Mekongga',
  );
  static const cultureTemplates = AdminRoute(
    '/admin/culture/templates',
    'Template Budaya',
  );
  static const cultureTemplateDetail = AdminRoute(
    '/admin/culture/templates/:id',
    'Detail Template Budaya',
  );
  static const cultureEdit = AdminRoute(
    '/admin/culture/:id/edit',
    'Edit Budaya Mekongga',
  );
  static const cultureDetail = AdminRoute(
    '/admin/culture/:id',
    'Detail Budaya Mekongga',
  );
  static const speaking = AdminRoute('/admin/speaking', 'Template Speaking');
  static const speakingCreate = AdminRoute(
    '/admin/speaking/create',
    'Tambah Template Speaking',
  );
  static const speakingEdit = AdminRoute(
    '/admin/speaking/:id/edit',
    'Edit Template Speaking',
  );
  static const speakingDetail = AdminRoute(
    '/admin/speaking/:id',
    'Detail Template Speaking',
  );
  static const reports = AdminRoute('/admin/reports', 'Progress');
  static const studentReport = AdminRoute(
    '/admin/reports/students/:id',
    'Progress Siswa',
  );
  static const classReport = AdminRoute(
    '/admin/reports/classes/:id',
    'Progress Kelas',
  );
  static const settings = AdminRoute('/admin/settings', 'Pengaturan');
  static const profile = AdminRoute('/admin/profile', 'Profil');

  static const menu = [
    dashboard,
    approvals,
    schools,
    classes,
    users,
    dictionary,
    knowledge,
    modules,
    quizzes,
    speaking,
    culture,
    reports,
    settings,
  ];

  static const all = [
    dashboard,
    approvals,
    approvalDetail,
    users,
    userDetail,
    schools,
    schoolCreate,
    schoolEdit,
    schoolDetail,
    classes,
    classCreate,
    classEdit,
    classDetail,
    dictionary,
    dictionaryCreate,
    dictionaryCategories,
    dictionaryImport,
    dictionaryEdit,
    dictionaryDetail,
    knowledge,
    knowledgeCreate,
    knowledgeEdit,
    knowledgeDetail,
    modules,
    moduleCreate,
    moduleEdit,
    materialCreate,
    materialEdit,
    moduleDetail,
    quizzes,
    quizCreate,
    quizEdit,
    questions,
    questionCreate,
    questionEdit,
    culture,
    cultureCreate,
    cultureTemplates,
    cultureTemplateDetail,
    cultureEdit,
    cultureDetail,
    speaking,
    speakingCreate,
    speakingEdit,
    speakingDetail,
    reports,
    studentReport,
    classReport,
    settings,
    profile,
  ];
}

class E2eAdminHelper {
  E2eAdminHelper(this.app, [E2eAuthHelper? auth])
    : auth = auth ?? E2eAuthHelper(app);

  final E2eAppHelper app;
  final E2eAuthHelper auth;

  Future<void> login() => auth.loginAsAdmin();

  Future<void> go(
    AdminRoute route, {
    Map<String, String> parameters = const {},
  }) async {
    final oldPath = app.router().routeInformationProvider.value.uri.path;
    final path = resolve(route, parameters);
    app.router().go(path);
    await app.tester.pump();
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (app.router().routeInformationProvider.value.uri.path != path &&
        DateTime.now().isBefore(deadline)) {
      await app.tester.pump(const Duration(milliseconds: 100));
    }
    expect(app.router().routeInformationProvider.value.uri.path, path);
    final screenKey = switch (route.path) {
      '/admin/dictionary/create' ||
      '/admin/dictionary/:id/edit' => const Key('adminScreen-dictionary-form'),
      '/admin/knowledge/create' ||
      '/admin/knowledge/:id/edit' => const Key('adminScreen-knowledge-form'),
      '/admin/reports/classes/:id' => const Key(
        'adminScreen-class-progress-detail',
      ),
      '/admin/reports/students/:id' => const Key(
        'adminScreen-student-progress-detail',
      ),
      _ => null,
    };
    final root = screenKey == null
        ? find.text(route.title)
        : find.byKey(screenKey);
    await app.pumpUntilFound(root.hitTestable());
    if (oldPath != path) {
      final oldKey = switch (oldPath) {
        '/admin/dictionary/create' => const Key('adminScreen-dictionary-form'),
        '/admin/knowledge/create' => const Key('adminScreen-knowledge-form'),
        _ => null,
      };
      if (oldKey != null) {
        while (find.byKey(oldKey).hitTestable().evaluate().isNotEmpty &&
            DateTime.now().isBefore(deadline)) {
          await app.tester.pump(const Duration(milliseconds: 100));
        }
      } else {
        await app.tester.pump();
      }
    }
    await app.waitForLoadingToFinish();
    if (find
        .byKey(const Key('adminError-dictionary-form'))
        .evaluate()
        .isNotEmpty) {
      fail('Kategori kamus gagal dimuat');
    }
    assertHealthy(
      title: screenKey == null ? route.title : null,
      root: screenKey == null ? null : root,
      path: path,
    );
  }

  String resolve(AdminRoute route, Map<String, String> parameters) {
    var path = route.path;
    for (final entry in parameters.entries) {
      path = path.replaceAll(':${entry.key}', Uri.encodeComponent(entry.value));
    }
    if (RegExp(r'/:\w+').hasMatch(path)) {
      fail('Parameter route belum lengkap: $path');
    }
    return path;
  }

  Future<void> openMenu(String label, AdminRoute expected) async {
    await app.tapAndWait(find.byKey(const Key('adminMenuButton')));
    await tapText(label, expected: find.text(expected.title));
    assertHealthy(title: expected.title);
  }

  Future<void> backTo(AdminRoute expected) async {
    await app.tapAndWait(
      find.byKey(const Key('adminBackButton')),
      expected: find.text(expected.title),
    );
    assertHealthy(title: expected.title);
  }

  Future<void> systemBackTo(AdminRoute expected) async {
    await app.tester.binding.handlePopRoute();
    await app.tester.pump();
    await app.pumpUntilFound(find.text(expected.title));
    await app.waitForLoadingToFinish();
    assertHealthy(title: expected.title);
  }

  Future<void> tapText(String text, {Finder? expected}) =>
      app.tapAndWait(find.text(text), expected: expected);

  Future<void> tapButton(String text, {Finder? expected}) async {
    final finder = find.widgetWithText(ButtonStyleButton, text);
    await app.tapAndWait(finder, expected: expected);
  }

  Future<void> search(String value, {Finder? field}) async {
    final target = field ?? find.byType(TextField).first;
    await app.enterTextSafely(target, value);
    await app.tester.pump(const Duration(milliseconds: 450));
    await app.tester.pump(const Duration(milliseconds: 100));
    await app.waitForLoadingToFinish();
    assertHealthy();
  }

  Future<void> expectSearchEmpty(String title) async {
    await app.pumpUntilFound(find.text(title));
    expect(find.text(title), findsWidgets);
    assertHealthy();
  }

  Future<void> clearSearch({Finder? field}) async {
    final target = field ?? find.byType(TextField).first;
    await app.enterTextSafely(target, '');
    await app.tester.pump(const Duration(milliseconds: 450));
    await app.tester.pump(const Duration(milliseconds: 100));
    await app.waitForLoadingToFinish();
    assertHealthy();
  }

  void assertHealthy({String? title, Finder? root, String? path}) {
    if (title != null) expect(find.text(title).hitTestable(), findsWidgets);
    if (root != null) expect(root.hitTestable(), findsOneWidget);
    if (path != null) {
      expect(app.router().routeInformationProvider.value.uri.path, path);
    }
    expect(
      find.byKey(const Key('adminMenuButton')).hitTestable(),
      find
              .byKey(const Key('adminBackButton'))
              .hitTestable()
              .evaluate()
              .isNotEmpty
          ? findsNothing
          : findsOneWidget,
    );
    expect(find.byKey(const Key('teacherMenuButton')), findsNothing);
    expect(find.byKey(const Key('studentMenuButton')), findsNothing);
    expect(find.text('Akses ditolak'), findsNothing);
    expect(find.text('Halaman tidak ditemukan.'), findsNothing);
    expect(find.text('Role tidak didukung.'), findsNothing);
    app.ensureNoFlutterException();
  }
}
