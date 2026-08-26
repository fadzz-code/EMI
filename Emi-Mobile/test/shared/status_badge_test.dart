import 'package:emi_mobile/shared/widgets/status_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps canonical status tones', () {
    expect(emiStatusToneFromKey('published'), EmiStatusTone.published);
    expect(emiStatusToneFromKey('draft'), EmiStatusTone.draft);
    expect(emiStatusToneFromKey('archived'), EmiStatusTone.archived);
    expect(emiStatusToneFromKey('unknown'), EmiStatusTone.neutral);
  });
}
