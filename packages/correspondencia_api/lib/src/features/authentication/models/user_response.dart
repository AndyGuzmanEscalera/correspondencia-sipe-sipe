/// UserResponse: DTO for the `user` block in /auth/login and /auth/me.
///
/// Mirrors the backend's UserSession Pydantic schema exactly:
/// id, username, email, employee_id, is_active.
class UserResponse {
  const UserResponse({
    required this.id,
    required this.username,
    required this.isActive,
    this.email,
    this.employeeId,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as String,
      username: json['username'] as String,
      isActive: json['is_active'] as bool? ?? true,
      email: json['email'] as String?,
      employeeId: json['employee_id'] as String?,
    );
  }

  final String id;
  final String username;
  final bool isActive;
  final String? email;
  final String? employeeId;
}
