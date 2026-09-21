import 'dart:convert';

import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRefreshInterceptor', () {
    test('401 on protected request triggers refresh and retries once', () async {
      var originalCalls = 0;
      var retryCalls = 0;
      var refreshCalls = 0;

      final tokenStore = AuthTokenStore()..setAccessToken('expired-token');
      final coordinator = AuthRefreshCoordinator(
        refreshTokens: () async {
          refreshCalls++;
          return 'fresh-token';
        },
        tokenStore: tokenStore,
        onSessionEnded: () {},
      );

      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost',
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      dio.interceptors.add(AuthInterceptor(tokenStore: tokenStore));
      dio.interceptors.add(
        AuthRefreshInterceptor(mainDio: dio, coordinator: coordinator),
      );
      dio.httpClientAdapter = _SequentialAdapter(
        handler: (options) {
          if (options.extra['__retried_after_refresh'] == true) {
            retryCalls++;
            return _jsonResponse(
              200,
              {'id': 'u1', 'username': 'admin', 'is_active': true},
            );
          }
          if (options.path.endsWith('/auth/me')) {
            originalCalls++;
            return _jsonResponse(401, {'detail': 'Unauthorized'});
          }
          fail('Unexpected request: ${options.path}');
        },
      );

      final api = ApiMethod(dio: dio);
      final json = await api.get('/auth/me', operation: 'auth.me');

      expect(json['username'], 'admin');
      expect(originalCalls, 1);
      expect(refreshCalls, 1);
      expect(retryCalls, 1);
      expect(tokenStore.accessToken, 'fresh-token');
    });
  });
}

ResponseBody _jsonResponse(int status, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _SequentialAdapter implements HttpClientAdapter {
  _SequentialAdapter({required this.handler});

  final ResponseBody Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }
}
