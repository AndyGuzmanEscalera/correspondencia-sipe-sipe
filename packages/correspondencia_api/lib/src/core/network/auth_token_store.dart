import 'package:flutter/foundation.dart';

/// In-memory store for the access token.
///
/// The access token is NOT persisted: it lives only while the app is
/// running. The refresh token is owned by the browser as an HttpOnly
/// cookie; Flutter code never reads or stores it.
class AuthTokenStore {
  String? _accessToken;

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  void clear() {
    _accessToken = null;
  }

  /// Debug-only: replaces the access token with an invalid value so
  /// [AuthRefreshInterceptor] can be exercised without waiting for JWT
  /// expiry. No-op in release builds.
  void debugInvalidateAccessToken() {
    if (!kDebugMode) return;
    _accessToken = 'debug-invalid-access-token';
  }
}
