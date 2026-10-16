import 'package:correspondencia_sipe_sipe/core/util/institutional_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UTC instant displays Bolivia time without mutating original', () {
    final utc = DateTime.utc(2026, 10, 15, 15, 32);
    expect(institutionalDate(utc), '15/10/2026 11:32');
    expect(utc.hour, 15);
    expect(institutionalDate(utc, pattern: 'HH:mm'), '11:32');
  });
  test('Bolivia day boundary and explicit offset are consistent', () {
    expect(institutionalDate(DateTime.utc(2026, 10, 16, 2, 5)),
        '15/10/2026 22:05');
    expect(institutionalDate(DateTime.parse('2026-10-15T11:32:00-04:00')),
        '15/10/2026 11:32');
  });
}
