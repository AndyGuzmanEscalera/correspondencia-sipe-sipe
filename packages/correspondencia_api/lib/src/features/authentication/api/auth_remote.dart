import '../models/auth_response.dart';
import '../models/user_response.dart';

/// Auth HTTP contract. [AuthApi] is the production implementation.
abstract class AuthRemote {
  Future<AuthResponse> login({
    required String username,
    required String password,
  });

  Future<String> refresh();

  Future<void> logout();

  Future<UserResponse> me();
}
