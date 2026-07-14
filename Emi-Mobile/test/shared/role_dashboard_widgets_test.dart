import 'package:emi_mobile/app/theme/emi_theme.dart';
import 'package:emi_mobile/shared/widgets/role_dashboard_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {double textScale = 1}) {
    return MaterialApp(
      theme: EmiTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('teacher class name stays within two lines at large text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 180,
          height: 150,
          child: SimpleStatItem(
            label: 'Kelas Saya',
            value: 'Kelas VII A yang Namanya Sangat Panjang',
            icon: Icons.groups_outlined,
          ),
        ),
        textScale: 1.4,
      ),
    );

    final text = tester.widget<Text>(
      find.text('Kelas VII A yang Namanya Sangat Panjang'),
    );
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick action keeps two-line labels aligned', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuickActionItem(
              label: 'Persetujuan Akun',
              icon: Icons.how_to_reg_outlined,
            ),
            QuickActionItem(label: 'Kuis', icon: Icons.quiz_outlined),
          ],
        ),
        textScale: 1.2,
      ),
    );

    final longLabel = tester.widget<Text>(find.text('Persetujuan Akun'));
    final shortLabel = tester.widget<Text>(find.text('Kuis'));
    expect(longLabel.maxLines, 2);
    expect(longLabel.textAlign, TextAlign.center);
    expect(shortLabel.textAlign, TextAlign.center);
    expect(
      tester.getTopLeft(find.byIcon(Icons.how_to_reg_outlined)).dy,
      tester.getTopLeft(find.byIcon(Icons.quiz_outlined)).dy,
    );
    expect(tester.takeException(), isNull);
  });
}
