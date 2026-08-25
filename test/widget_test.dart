import 'package:flutter_test/flutter_test.dart';
import 'package:dtex_erp/theme.dart';

void main() {
  test('money formats with thousands separators', () {
    expect(money('৳', 30100), '৳30,100');
    expect(money('৳', 1234567.5), '৳1,234,567.50');
  });
}
