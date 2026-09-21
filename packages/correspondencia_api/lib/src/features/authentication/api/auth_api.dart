import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/auth_response.dart';
import '../models/user_response.dart';
import 'auth_remote.dart';

/// AuthApi: thin wrapper over [ApiMethod] for the auth endpoints.
///
/// Uses the [refreshDio] (configured in ApiClient) for login / refresh /
/// logout, and the [mainDio] for /auth/me.
///
/// The Dio instances are passed in via [ApiMethod] which already routes
/// auth endpoints through the refresh-dio.
class AuthApi implements AuthRemote {
  AuthApi({required ApiMethod mainApi, required ApiMethod refreshApi})
      : _mainApi = mainApi,
        _refreshApi = refreshApi;

  final ApiMethod _mainApi;
  final ApiMethod _refreshApi;

  /// POST /auth/login
  @override
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final json = await _refreshApi.post(
      Endpoints.authLogin,
      data: {'username': username, 'password': password},
      operation: 'auth.login',
    );
    return AuthResponse.fromJson(json);
  }

  /// POST /auth/refresh.
  ///
  /// Returns the new access token. The browser sends the HttpOnly
  /// refresh cookie automatically.
  @override
  Future<String> refresh() async {
    final json = await _refreshApi.post(
      Endpoints.authRefresh,
      operation: 'auth.refresh',
    );
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw StateError('AuthApi.refresh: missing access_token');
    }
    return token;
  }

  /// POST /auth/logout. Best-effort.
  @override
  Future<void> logout() async {
    await _refreshApi.post(
      Endpoints.authLogout,
      operation: 'auth.logout',
      allowEmptyBody: true,
    );
  }

  /// GET /auth/me.
  @override
  Future<UserResponse> me() async {
    final json = await _mainApi.get(
      Endpoints.authMe,
      operation: 'auth.me',
    );
    return UserResponse.fromJson(json);
  }
}
