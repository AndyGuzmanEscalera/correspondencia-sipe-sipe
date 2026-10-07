import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// Ejecutar sin define para desarrollo y con /api en Chrome para la demo.
const _isDemo = String.fromEnvironment('API_BASE_URL') == '/api';

void main() {
  const expectedBaseUrl = _isDemo ? '/api' : 'http://localhost:8000';

  test('ApiConfig usa el default local o el define demo /api', () {
    expect(ApiConfig.baseUrl, expectedBaseUrl);
  });

  test('clientes principal y refresh conservan la base y credenciales', () {
    final tokenStore = AuthTokenStore();
    final coordinator = AuthRefreshCoordinator(
      refreshTokens: () async => 'refreshed-token',
      tokenStore: tokenStore,
      onSessionEnded: () {},
    );
    final main = ApiClient.buildMain(
      tokenStore: tokenStore,
      coordinator: coordinator,
    );
    final refresh = ApiClient.buildRefresh();
    addTearDown(() {
      main.close(force: true);
      refresh.close(force: true);
    });

    for (final client in [main, refresh]) {
      expect(client.options.baseUrl, expectedBaseUrl);
      expect(client.options.extra['withCredentials'], isTrue);
      for (final path in [
        '/auth/login',
        '/auth/refresh',
        '/auth/logout',
        '/auth/me',
        '/correspondences',
      ]) {
        final request = Options().compose(
          client.options,
          path,
        );
        expect(request.uri.toString(), '$expectedBaseUrl$path');
      }
    }
  });
}
