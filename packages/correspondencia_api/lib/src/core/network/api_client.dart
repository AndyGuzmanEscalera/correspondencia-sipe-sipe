import 'package:dio/dio.dart';

import 'configure_web_adapter_stub.dart'
    if (dart.library.html) 'configure_web_adapter_web.dart';
import 'api_config.dart';
import 'api_interceptor.dart';
import 'api_method.dart';
import 'auth_interceptor.dart';
import 'auth_refresh_coordinator.dart';
import 'auth_refresh_interceptor.dart';
import 'auth_token_store.dart';
import 'credentials_interceptor.dart';

/// Builds the two Dio instances used by the app, plus their interceptors.
///
/// * [buildMain] carries [AuthInterceptor] + [AuthRefreshInterceptor].
///   Used for any request that needs the Authorization header and may
///   need an automatic refresh.
///
/// * [buildRefresh] carries no interceptors. Used only for login /
///   refresh / logout, so a 401 there cannot trigger another refresh
///   and create a recursion loop.
///
/// Both enable `withCredentials = true` on Flutter Web so the HttpOnly
/// refresh cookie is sent with each request automatically by the browser.
class ApiClient {
  ApiClient._();

  static Dio buildMain({
    required AuthTokenStore tokenStore,
    required AuthRefreshCoordinator coordinator,
  }) {
    final dio = _baseDio();
    dio.interceptors.add(ApiInterceptor());
    dio.interceptors.add(const CredentialsInterceptor());
    dio.interceptors.add(AuthInterceptor(tokenStore: tokenStore));
    dio.interceptors.add(
      AuthRefreshInterceptor(
        mainDio: dio,
        coordinator: coordinator,
      ),
    );
    return dio;
  }

  static Dio buildRefresh() {
    final dio = _baseDio();
    dio.interceptors.add(ApiInterceptor());
    dio.interceptors.add(const CredentialsInterceptor());
    // No auth / refresh interceptors on this instance.
    return dio;
  }

  static Dio _baseDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        // NOTE: `sendTimeout` is intentionally omitted. On Flutter Web,
        // GET requests cannot send a body, and Dio's web adapter logs a
        // warning whenever sendTimeout is set for a body-less request.
        // For POST/PUT/PATCH we rely on `connectTimeout` + `receiveTimeout`,
        // which is the recommended pattern.
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        // BrowserHttpClientAdapter reads this official Dio Web option and
        // sends HttpOnly cookies on cross-origin requests. It belongs in
        // BaseOptions so BOTH mainDio and refreshDio carry credentials.
        extra: const {'withCredentials': true},
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    configureWebAdapter(dio);
    return dio;
  }

  /// Helper: build an [ApiMethod] around a given [Dio].
  static ApiMethod apiMethodFor(Dio dio) => ApiMethod(dio: dio);
}
