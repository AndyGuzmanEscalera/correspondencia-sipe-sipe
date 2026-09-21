import 'package:dio/dio.dart';

import 'api_logger.dart';
import 'auth_refresh_coordinator.dart';

/// Intercepts 401 responses from protected endpoints and:
/// 1. Asks the [AuthRefreshCoordinator] to refresh (single-flight).
/// 2. If refresh succeeded, retries the original request once with the new
///    access token.
/// 3. If refresh failed, the coordinator has already cleared the token
///    and notified the app; we just propagate the original error.
///
/// Requests targeting the auth endpoints themselves (`/auth/login`,
/// `/auth/refresh`, `/auth/logout`) MUST NOT trigger another refresh.
///
/// Uses [onResponse] because [ApiClient] sets `validateStatus` so 401 arrives
/// as a normal response before [ApiMethod] maps it to an exception.
class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor({
    required Dio mainDio,
    required AuthRefreshCoordinator coordinator,
  })  : _mainDio = mainDio,
        _coordinator = coordinator;

  final Dio _mainDio;
  final AuthRefreshCoordinator _coordinator;

  static const _refreshPath = '/auth/refresh';
  static const _authPaths = <String>{
    '/auth/login',
    _refreshPath,
    '/auth/logout',
  };

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final retried = await _retryIfUnauthorized(
      response.requestOptions,
      statusCode: response.statusCode,
    );
    if (retried != null) {
      handler.resolve(retried);
      return;
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retried = await _retryIfUnauthorized(
      err.requestOptions,
      statusCode: err.response?.statusCode,
    );
    if (retried != null) {
      handler.resolve(retried);
      return;
    }
    handler.next(err);
  }

  Future<Response<dynamic>?> _retryIfUnauthorized(
    RequestOptions requestOptions, {
    required int? statusCode,
  }) async {
    final path = requestOptions.path;

    final isAuthEndpoint = _authPaths.any(path.endsWith);
    final retriedAlready =
        requestOptions.extra['__retried_after_refresh'] == true;

    if (statusCode != 401 || isAuthEndpoint || retriedAlready) {
      return null;
    }

    ApiLogger.logSave(
      'AUTH REFRESH ===> original request 401 path=$path ${DateTime.now()}',
    );

    final newToken = await _coordinator.refresh();
    if (newToken == null) {
      return null;
    }

    ApiLogger.logSave(
      'AUTH REFRESH ===> refresh 200, retrying path=$path ${DateTime.now()}',
    );

    final retried = requestOptions
      ..headers['Authorization'] = 'Bearer $newToken'
      ..extra['__retried_after_refresh'] = true;

    try {
      final response = await _mainDio.fetch<dynamic>(retried);
      ApiLogger.logSave(
        'AUTH REFRESH ===> retry ${response.statusCode} path=$path '
        '${DateTime.now()}',
      );
      return response;
    } on DioException {
      return null;
    }
  }
}
