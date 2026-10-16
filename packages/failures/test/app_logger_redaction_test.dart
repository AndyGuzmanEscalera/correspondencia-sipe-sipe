import 'dart:convert';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared logger sanitizes initial password and nested JSON', () {
    final input = {
      'initial_password': 'PRIVATE VALUE',
      'nested': [
        {
          'newPassword': 'NEW PRIVATE VALUE',
          'token': 'PRIVATE TOKEN',
          'label': 'visible'
        }
      ]
    };
    final result = jsonEncode(AppLogger.sanitize(input));
    expect(result, isNot(contains('PRIVATE')));
    expect(result, contains('visible'));
    expect(AppLogger.sanitizeMessage(jsonEncode(input)),
        isNot(contains('PRIVATE')));
    final prefixed = AppLogger.sanitizeMessage(
        'REQUEST users.create ===> ${jsonEncode(input)}');
    expect(prefixed, isNot(contains('PRIVATE')));
    expect(prefixed, contains('visible'));
    expect(prefixed, startsWith('REQUEST users.create ===> '));
  });
  test('unstructured messages never leave partial credentials', () {
    for (final value in [
      'initial_password=PRIVATE VALUE WITH SPACES',
      'Authorization: Bearer PRIVATE_TOKEN',
      'Cookie: PRIVATE=VALUE; OTHER=SECRET',
      'new_password="PRIVATE VALUE"',
      r'password: "PRIVATE\"PRIVATE TAIL"',
      'password: "PRIVATE unterminated PRIVATE'
    ]) {
      final output = AppLogger.sanitizeMessage(value);
      expect(output, isNot(contains('PRIVATE')));
      expect(output, isNot(contains('SECRET')));
      expect(output, contains('***'));
    }
    expect(AppLogger.sanitizeMessage('Operation createUser failed: HTTP 409'),
        'Operation createUser failed: HTTP 409');
  });
}
