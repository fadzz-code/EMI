import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/helpers/e2e_app_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2eAppHelper scoped scroll regression test', (tester) async {
    final app = E2eAppHelper(tester, binding);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 200,
                child: ListView.builder(
                  key: const Key('wrong-list'),
                  itemCount: 100,
                  itemBuilder: (_, i) => Text('Wrong $i'),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 200,
                right: 0,
                key: const Key('adminScreen-knowledge-form'),
                child: ListView.builder(
                  controller:
                      ScrollController(), // Added explicit controller for reset isolation if needed, though drag should work
                  itemCount: 100,
                  itemBuilder: (_, i) {
                    return ListTile(title: Text('Target $i'), onTap: () {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final targetEnd = find.text('Target 95');
    final scope = find.byKey(const Key('adminScreen-knowledge-form'));

    // Tap and wait with scope
    await app.tapAndWait(
      targetEnd,
      within: scope,
      timeout: const Duration(seconds: 15),
    );

    // Verify it scrolled and found it
    expect(targetEnd.hitTestable(), findsOneWidget);

    // Scroll back to top
    final targetStart = find.text('Target 5');
    await app.tapAndWait(
      targetStart,
      within: scope,
      timeout: const Duration(seconds: 15),
    );
    expect(targetStart.hitTestable(), findsOneWidget);
  });
}
