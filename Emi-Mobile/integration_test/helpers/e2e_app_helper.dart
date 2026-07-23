import 'package:emi_mobile/app/router/app_router.dart';
import 'package:emi_mobile/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

class E2eAppHelper {
  E2eAppHelper(this.tester, this.binding);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;

  Future<void> launchApp() async {
    await tester.pumpWidget(const SizedBox.shrink());
    app.main();
    await pumpUntilAny([
      find.byKey(const Key('emailField')),
      find.byKey(const Key('adminMenuButton')),
      find.byKey(const Key('teacherMenuButton')),
      find.byKey(const Key('studentMenuButton')),
    ]);
    await waitForLoadingToFinish();
    ensureNoFlutterException();
  }

  Future<void> pumpUntilAny(
    List<Finder> finders, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (finders.every((finder) => finder.evaluate().isEmpty) &&
        DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (finders.every((finder) => finder.evaluate().isEmpty)) {
      fail('Tidak ada widget target ditemukan dalam $timeout');
    }
  }

  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      finder,
      findsWidgets,
      reason: 'Widget tidak ditemukan dalam $timeout',
    );
  }

  Future<void> waitForLoadingToFinish({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty &&
        DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      fail('Loading tidak selesai dalam $timeout');
    }
    await tester.pump();
  }

  Future<void> enterTextSafely(Finder finder, String value) async {
    await pumpUntilFound(finder);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.enterText(finder, value);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  Future<void> tapAndWait(
    Finder finder, {
    Finder? expected,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await pumpUntilFound(finder);
    if (finder.hitTestable().evaluate().isEmpty) {
      final listView = find.byType(ListView);
      if (listView.evaluate().isEmpty) {
        fail('Widget ditemukan tetapi tidak dapat disentuh: $finder');
      }
      for (
        var attempt = 0;
        attempt < 10 && finder.hitTestable().evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(listView.last, const Offset(0, -200));
        await tester.pump();
      }
      if (finder.hitTestable().evaluate().isEmpty) {
        fail('Widget tidak dapat digulir ke viewport: $finder');
      }
    }
    await tester.tap(finder.hitTestable());
    await tester.pump();
    if (expected != null) {
      await pumpUntilFound(expected, timeout: timeout);
    }
    await waitForLoadingToFinish(timeout: timeout);
    ensureNoFlutterException();
  }

  Future<void> closeKeyboard() async {
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
  }

  GoRouter router() {
    final context = tester.element(find.byType(MaterialApp));
    return ProviderScope.containerOf(context).read(appRouterProvider);
  }

  void ensureNoFlutterException() {
    final exception = tester.takeException();
    expect(exception, isNull, reason: 'Flutter exception: $exception');
  }

  Future<void> takeFailureScreenshot(String name) async {
    try {
      await binding.takeScreenshot(name);
    } on Object {
      return;
    }
  }
}
