import 'package:flutter_test/flutter_test.dart';
import 'package:roro/data/rollator_policy.dart';

void main() {
  test('first and second accounts can claim a rollator', () {
    final firstClaim = RollatorPolicy.claim(const [], 'user-a');
    expect(firstClaim, ['user-a']);

    final secondClaim = RollatorPolicy.claim(firstClaim, 'user-b');
    expect(secondClaim, ['user-a', 'user-b']);
  });

  test('third account is rejected', () {
    expect(() => RollatorPolicy.claim(const ['user-a', 'user-b'], 'user-c'), throwsStateError);
  });

  test('duplicate user keeps the same membership list', () {
    final existing = ['user-a', 'user-b'];
    final updated = RollatorPolicy.claim(existing, 'user-a');

    expect(updated, existing);
  });
}