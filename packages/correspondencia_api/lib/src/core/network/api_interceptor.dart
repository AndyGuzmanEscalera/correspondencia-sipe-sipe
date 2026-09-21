import 'package:dio/dio.dart';

/// Ensures JSON requests like Inventario / Capturador [ApiInterceptor].
class ApiInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.contentType = 'application/json';
    handler.next(options);
  }
}
