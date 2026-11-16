import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

void main() {
  const expectedBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: ApiConfig.environment == 'production'
          ? ApiConfig.productionBaseUrl
          : kIsWeb && ApiConfig.environment == 'qa'
              ? '/api'
              : 'http://localhost:8000');

  test('ApiConfig permite API separada en producción y override explícito', () {
    expect(ApiConfig.baseUrl, expectedBaseUrl);
  });

  test('producción usa API directa HTTPS sin prefijo /api', () {
    final uri = Uri.parse(ApiConfig.productionBaseUrl);
    expect(uri.scheme, 'https');
    expect(uri.host, 'api-correspondencia.sipesipe.gob.bo');
    expect(ApiConfig.productionBaseUrl,
        'https://api-correspondencia.sipesipe.gob.bo');
    expect(uri.path, isEmpty);
    expect(uri.userInfo, isEmpty);
  });

  test('login y sesión de producción apuntan directamente a FastAPI', () {
    final client = Dio(BaseOptions(baseUrl: ApiConfig.productionBaseUrl));
    addTearDown(() => client.close(force: true));
    for (final entry in {
      Endpoints.authLogin: 'POST',
      Endpoints.authMe: 'GET',
    }.entries) {
      final request =
          Options(method: entry.value).compose(client.options, entry.key);
      expect(request.method, entry.value);
      expect(request.uri.toString(),
          'https://api-correspondencia.sipesipe.gob.bo${entry.key}');
      expect(request.uri.path, isNot(startsWith('/api/')));
    }
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
        Endpoints.authLogin,
        Endpoints.authRefresh,
        Endpoints.authLogout,
        Endpoints.authMe,
        Endpoints.correspondences,
        Endpoints.dashboard,
        Endpoints.notifications,
        Endpoints.notificationCount,
        Endpoints.notificationsReadAll,
        Endpoints.notificationRead('example'),
        Endpoints.reports,
        Endpoints.reportExport,
        Endpoints.reportExportXlsx,
        Endpoints.reportExportPdf,
        Endpoints.correspondenceAttachments('example'),
        Endpoints.correspondenceAttachmentDownload('example', 'file'),
      ]) {
        final request = Options().compose(
          client.options,
          path,
        );
        expect(request.uri.toString(), '$expectedBaseUrl$path');
        expect(request.uri.path, isNot(contains('/api/api/')));
      }
    }
  });
}
