import 'package:flutter_test/flutter_test.dart';
import 'package:sample_flutter_lib/sample_flutter_lib.dart';

void main() {
  test('add returns the sum of two integers', () {
    expect(add(left: 2, right: 3), 5);
  });
}
