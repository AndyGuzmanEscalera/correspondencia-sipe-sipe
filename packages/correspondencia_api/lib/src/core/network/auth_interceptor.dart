import 'package:dio/dio.dart';

import 'auth_token_store.dart';

/// Adds `Authorization: Bearer <access_token>` when a token is present.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenStore});

  final AuthTokenStore tokenStore;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStore.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
