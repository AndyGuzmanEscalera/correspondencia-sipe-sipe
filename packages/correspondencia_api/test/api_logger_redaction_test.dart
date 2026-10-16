import 'dart:convert';
import 'package:correspondencia_api/src/core/network/api_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const keys = [
    'password',
    'initial_password',
    'new_password',
    'current_password',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'cookie',
    'secret',
    'initialPassword',
    'CURRENT-PASSWORD',
    'client_secret'
  ];
  for (final key in keys) {
    test('API request/response hides complete value of $key', () {
      final input = {
        key: 'SENSITIVE $key full value',
        'username': 'tester',
        'count': 3
      };
      for (final output in [
        ApiLogger.encodePayload(input),
        ApiLogger.encodeResponse(input),
        ApiLogger.redactString(jsonEncode(input))
      ]) {
        expect(output, isNot(contains('SENSITIVE')));
        final decoded = jsonDecode(output) as Map;
        expect(decoded[key], '***');
        expect(decoded['username'], 'tester');
        expect(decoded['count'], 3);
      }
    });
  }
  test('nested credentials are hidden while useful fields remain', () {
    final output = ApiLogger.encodePayload({
      'items': [
        {'initial_password': 'unique-private-value', 'subject': 'Solicitud'},
        {'token': 'unique-token-value', 'ok': true},
      ]
    });
    expect(output, isNot(contains('unique-')));
    expect(output, contains('Solicitud'));
    expect(output, contains('true'));
  });
}
