import 'package:emi_mobile/app/app.dart';
import 'package:emi_mobile/app/router/app_router.dart';
import 'package:emi_mobile/features/auth/presentation/auth_controller.dart';
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

  Future<void> launchApp({List<Override>? overrides}) async {
    await tester.pumpWidget(const SizedBox.shrink());
    if (overrides == null) {
      app.main();
    } else {
      await tester.pumpWidget(
        ProviderScope(overrides: overrides, child: const EmiMobileApp()),
      );
    }
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

  Future<void> enterTextSafely(
    Finder finder,
    String value, {
    Finder? within,
  }) async {
    await pumpUntilFound(finder);
    await tester.ensureVisible(finder);
    await pumpUntilFound(finder.hitTestable());
    if (within != null) {
      await reveal(finder, within: within);
    }
    await tester.tap(finder.hitTestable());
    await tester.enterText(finder, value);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  Future<void> reveal(
    Finder finder, {
    Finder? within,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    for (final offset in const [Offset(0, -300), Offset(0, 300)]) {
      while (finder.hitTestable().evaluate().isEmpty &&
          DateTime.now().isBefore(deadline)) {
        Finder target = find.byType(Scrollable).hitTestable();
        if (within != null) {
          await pumpUntilFound(within.hitTestable(), timeout: timeout);
          target = find.descendant(of: within, matching: target);
        }
        if (target.evaluate().isEmpty) break;

        final scrollable = tester.state<ScrollableState>(target.last);
        final initialOffset = scrollable.position.pixels;
        await tester.drag(target.last, offset);
        await tester.pump();
        final finalOffset = scrollable.position.pixels;
        if (initialOffset == finalOffset) break;
      }
      if (finder.hitTestable().evaluate().isNotEmpty) return;
    }
    fail('Widget tidak dapat ditampilkan dalam $timeout: $finder');
  }

  Future<void> tapAndWait(
    Finder finder, {
    Finder? expected,
    Finder? within,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (finder.hitTestable().evaluate().isEmpty) {
      Finder target = find.byType(Scrollable).hitTestable();
      if (within != null) {
        await pumpUntilFound(within, timeout: timeout);
        target = find.descendant(of: within, matching: target);
      }
      final deadline = DateTime.now().add(timeout);
      var offsetValues = const [Offset(0, -300), Offset(0, 300)];

      for (final offset in offsetValues) {
        bool didScroll = false;
        while (finder.hitTestable().evaluate().isEmpty &&
            DateTime.now().isBefore(deadline)) {
          final resolvedTarget = target.evaluate().isNotEmpty
              ? target
              : find.byType(Scrollable).hitTestable();
          if (resolvedTarget.evaluate().isEmpty) break;

          final scrollable = tester.state<ScrollableState>(resolvedTarget.last);
          final initialOffset = scrollable.position.pixels;
          await tester.drag(resolvedTarget.last, offset);
          await tester.pump();
          didScroll = true;

          final finalOffset = scrollable.position.pixels;
          if (initialOffset == finalOffset) break;
        }
        if (finder.hitTestable().evaluate().isNotEmpty) break;
        // if we didn't find it going one way, jump back aggressively before trying the other way
        if (didScroll && target.evaluate().isNotEmpty) {
          for (int i = 0; i < 20; i++) {
            final scrollable = tester.state<ScrollableState>(target.last);
            final initialOffset = scrollable.position.pixels;
            await tester.drag(
              target.last,
              Offset(0, offset.dy > 0 ? -1000 : 1000),
            );
            await tester.pump();
            final finalOffset = scrollable.position.pixels;
            if (initialOffset == finalOffset) break;
          }
        }
      }
      if (finder.hitTestable().evaluate().isEmpty) {
        if (target.evaluate().isEmpty && finder.evaluate().isEmpty) {
          await pumpUntilFound(finder, timeout: timeout);
        } else {
          fail('Widget tidak dapat digulir ke viewport: $finder');
        }
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

  ProviderContainer container() {
    final context = tester.element(find.byType(MaterialApp));
    return ProviderScope.containerOf(context);
  }

  GoRouter router() => container().read(appRouterProvider);

  Future<void> clearSessionSafely() async {
    await container().read(authControllerProvider.notifier).logout();
    await pumpUntilFound(find.byKey(const Key('emailField')));
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
