import 'package:dio/dio.dart';

/// Sends browser cookies (HttpOnly refresh token) on Flutter Web.
///
/// Required for cross-origin calls from `localhost:5000` (Flutter) to
/// `localhost:8000` (FastAPI) when `withCredentials` is enabled.
class CredentialsInterceptor extends Interceptor {
  const CredentialsInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['withCredentials'] = true;
    handler.next(options);
  }
}
