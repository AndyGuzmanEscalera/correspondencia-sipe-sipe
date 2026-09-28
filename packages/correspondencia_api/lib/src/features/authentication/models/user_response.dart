import 'me_employee_response.dart';

/// UserResponse: DTO for the `user` block in /auth/login and /auth/me.
class UserResponse {
  const UserResponse({
    required this.id,
    required this.username,
    required this.isActive,
    this.email,
    this.employeeId,
    this.employee,
    this.roles = const [],
    this.permissions = const [],
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'] as List<dynamic>? ?? const [];
    final rawPermissions = json['permissions'] as List<dynamic>? ?? const [];
    final employeeJson = json['employee'] as Map<String, dynamic>?;
    return UserResponse(
      id: json['id'] as String,
      username: json['username'] as String,
      isActive: json['is_active'] as bool? ?? true,
      email: json['email'] as String?,
      employeeId: json['employee_id'] as String?,
      employee: employeeJson == null
          ? null
          : MeEmployeeContextResponse.fromJson(employeeJson),
      roles: rawRoles.map((role) => role as String).toList(),
      permissions: rawPermissions.map((permission) => permission as String).toList(),
    );
  }

  final String id;
  final String username;
  final bool isActive;
  final String? email;
  final String? employeeId;
  final MeEmployeeContextResponse? employee;
  final List<String> roles;
  final List<String> permissions;
}
