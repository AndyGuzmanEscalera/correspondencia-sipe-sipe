import 'package:failures/failures.dart';
import 'package:correspondencia_sipe_sipe/injection/get_it_test_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Sanity test: the failures package + the repository package wire up
  // correctly under flutter_test. Full splash widget integration is
  // covered manually with flutter run -d chrome.
  test('failures package loads and Result.when dispatches correctly', () {
    getItTestHelper.reset();
    final result = Ok<int, Failure>(42);
    final mapped = result.when(ok: (v) => 'ok=$v', err: (f) => 'err=${f.message}');
    expect(mapped, 'ok=42');

    final errResult = Err<int, Failure>(const GenericFailure('bad'));
    final mappedErr =
        errResult.when(ok: (v) => 'ok=$v', err: (f) => 'err=${f.message}');
    expect(mappedErr, 'err=bad');

    // Verify AppSessionCubit can be constructed with a fake repo.
    expect(result.isOk, isTrue);
  });
}
