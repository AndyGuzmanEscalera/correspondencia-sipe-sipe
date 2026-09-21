import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRemote implements AuthRemote {
  _FakeAuthRemote({
    this.refreshResult,
    this.meResult,
    this.refreshError,
  });

  final String? refreshResult;
  final UserResponse? meResult;
  final Object? refreshError;

  @override
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> refresh() async {
    if (refreshError != null) throw refreshError!;
    return refreshResult ?? 'access-token';
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserResponse> me() async {
    if (meResult == null) {
      throw StateError('me() not stubbed');
    }
    return meResult!;
  }
}

const _user = UserResponse(
  id: 'user-1',
  username: 'admin',
  isActive: true,
);

void main() {
  group('AuthenticationRepository.restoreSession', () {
    test('refresh 200 + me 200 returns Ok(UserSession)', () async {
      final tokenStore = AuthTokenStore();
      final repo = AuthenticationRepository(
        authApi: _FakeAuthRemote(
          refreshResult: 'new-token',
          meResult: _user,
        ),
        tokenStore: tokenStore,
      );

      final result = await repo.restoreSession();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull(), isA<UserSession>());
      expect(result.valueOrNull()?.username, 'admin');
      expect(tokenStore.accessToken, 'new-token');
    });

    test('refresh 401 returns Ok(null) — no session', () async {
      final tokenStore = AuthTokenStore();
      final repo = AuthenticationRepository(
        authApi: _FakeAuthRemote(
          refreshError: UnauthorizedException('expired'),
        ),
        tokenStore: tokenStore,
      );

      final result = await repo.restoreSession();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull(), isNull);
      expect(tokenStore.accessToken, isNull);
    });

    test('refresh NetworkException returns Err(NetworkFailure)', () async {
      final tokenStore = AuthTokenStore();
      final repo = AuthenticationRepository(
        authApi: _FakeAuthRemote(
          refreshError: const NetworkException('Sin conexión con el servidor'),
        ),
        tokenStore: tokenStore,
      );

      final result = await repo.restoreSession();

      expect(result.isErr, isTrue);
      expect(result.failureOrNull(), isA<NetworkFailure>());
    });
  });
}
