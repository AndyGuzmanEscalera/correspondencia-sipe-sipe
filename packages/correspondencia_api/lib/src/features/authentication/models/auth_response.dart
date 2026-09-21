import 'user_response.dart';

/// AuthResponse: top-level DTO for POST /auth/login.
///
/// Captures the access token + expiry + user payload.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      expiresIn: json['expires_in'] as int,
      user: UserResponse.fromJson(
        (json['user'] as Map).cast<String, dynamic>(),
      ),
    );
  }

  final String accessToken;
  final int expiresIn;
  final UserResponse user;
}
