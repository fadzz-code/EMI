import 'package:emi_mobile/features/dictionary/data/dictionary_providers.dart';
import 'package:emi_mobile/features/modules/data/student_module_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module query keeps stable provider identity', () {
    const first = StudentModuleQuery(status: 'completed');
    const second = StudentModuleQuery(status: 'completed');

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('dictionary query keeps stable provider identity', () {
    const first = DictionaryQuery(search: 'monga', categoryId: 'category-1');
    const second = DictionaryQuery(search: 'monga', categoryId: 'category-1');

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });
}
