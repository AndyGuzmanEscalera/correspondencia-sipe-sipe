import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRefreshCoordinator', () {
    test('concurrent refresh calls execute refreshFn only once', () async {
      var refreshCalls = 0;
      final tokenStore = AuthTokenStore();
      final coordinator = AuthRefreshCoordinator(
        refreshTokens: () async {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return 'rotated-token';
        },
        tokenStore: tokenStore,
        onSessionEnded: () {},
      );

      final results = await Future.wait([
        coordinator.refresh(),
        coordinator.refresh(),
        coordinator.refresh(),
      ]);

      expect(refreshCalls, 1);
      expect(results, everyElement('rotated-token'));
      expect(tokenStore.accessToken, 'rotated-token');
    });
  });
}
