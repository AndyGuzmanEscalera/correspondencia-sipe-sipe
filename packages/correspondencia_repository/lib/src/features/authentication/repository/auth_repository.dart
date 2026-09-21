import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';

import '../entities/user_session.dart';
import '../mappers/user_response_mapper.dart';

/// Authentication repository — every public method returns [Result].
class AuthenticationRepository {
  AuthenticationRepository({
    required AuthRemote authApi,
    required AuthTokenStore tokenStore,
  })  : _authApi = authApi,
        _tokenStore = tokenStore;

  final AuthRemote _authApi;
  final AuthTokenStore _tokenStore;

  /// POST /auth/login.
  Future<Result<UserSession, Failure>> signIn({
    required String username,
    required String password,
  }) {
    return handleExceptions<UserSession>(
      () async {
        final response = await _authApi.login(
          username: username,
          password: password,
        );
        _tokenStore.setAccessToken(response.accessToken);
        return response.user.toEntity();
      },
      feature: 'authentication',
      operation: 'signIn',
    );
  }

  /// POST /auth/logout. Best-effort: local state is always cleared.
  Future<Result<void, Failure>> logout() async {
    final result = await handleExceptions<void>(
      () => _authApi.logout(),
      feature: 'authentication',
      operation: 'logout',
    );
    _tokenStore.clear();
    return result;
  }

  /// Restaura sesión desde la cookie HttpOnly refresh.
  ///
  /// * [Ok(session)] — sesión válida.
  /// * [Ok(null)] — sin sesión (401 en refresh, cold start normal).
  /// * [Err] — fallo de red, timeout, servidor, etc.
  Future<Result<UserSession?, Failure>> restoreSession() async {
    final refreshResult = await handleExceptions<String>(
      () => _authApi.refresh(),
      feature: 'authentication',
      operation: 'refresh',
    );

    if (refreshResult case Err<String, Failure>(:final failure)) {
      if (failure is UnauthorizedFailure) {
        return ok<UserSession?, Failure>(null);
      }
      return Err<UserSession?, Failure>(failure);
    }

    final token = refreshResult.valueOrNull();
    if (token == null || token.isEmpty) {
      return ok<UserSession?, Failure>(null);
    }
    _tokenStore.setAccessToken(token);

    final userResult = await currentUser();
    return userResult.when(
      ok: (user) => ok<UserSession?, Failure>(user),
      err: (failure) => Err<UserSession?, Failure>(failure),
    );
  }

  /// GET /auth/me.
  Future<Result<UserSession, Failure>> currentUser() {
    return handleExceptions<UserSession>(
      () async => (await _authApi.me()).toEntity(),
      feature: 'authentication',
      operation: 'currentUser',
    );
  }
}
