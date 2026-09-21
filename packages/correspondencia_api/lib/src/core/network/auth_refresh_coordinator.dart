import 'package:correspondencia_api/correspondencia_api.dart';

/// Coordinates the refresh-token rotation.
///
/// * Holds the single-flight state: if N requests receive 401 simultaneously,
///   only ONE POST /auth/refresh goes out; the rest await the same Future.
/// * On success, writes the new access token into [AuthTokenStore].
/// * On failure, clears [AuthTokenStore] and notifies [onSessionEnded]
///   so the AppSessionCubit can return to the unauthenticated state.
///
/// The callback `refreshTokens` is supplied by GetIt bootstrap and calls
/// `AuthApi.refresh()` (which goes through the refreshDio). It returns
/// the new access token (string) or null on failure.
class AuthRefreshCoordinator {
  AuthRefreshCoordinator({
    required Future<String?> Function() refreshTokens,
    required AuthTokenStore tokenStore,
    required void Function() onSessionEnded,
  })  : _refreshTokens = refreshTokens,
        _tokenStore = tokenStore,
        _onSessionEnded = onSessionEnded;

  final Future<String?> Function() _refreshTokens;
  final AuthTokenStore _tokenStore;
  final void Function() _onSessionEnded;

  Future<String?>? _inFlightRefresh;

  /// Returns the new access token (also written into [tokenStore]),
  /// or null on failure.
  Future<String?> refresh() {
    final inFlight = _inFlightRefresh;
    if (inFlight != null) return inFlight;

    final future = _doRefresh().whenComplete(() {
      _inFlightRefresh = null;
    });
    _inFlightRefresh = future;
    return future;
  }

  Future<String?> _doRefresh() async {
    try {
      final token = await _refreshTokens();
      if (token == null || token.isEmpty) {
        _tokenStore.clear();
        _onSessionEnded();
        return null;
      }
      _tokenStore.setAccessToken(token);
      return token;
    } catch (_) {
      _tokenStore.clear();
      _onSessionEnded();
      return null;
    }
  }
}
