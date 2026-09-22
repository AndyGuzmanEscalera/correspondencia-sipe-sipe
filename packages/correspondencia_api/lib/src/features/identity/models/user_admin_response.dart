class UserAdminResponse {
  const UserAdminResponse({
    required this.id,
    required this.username,
    required this.isActive,
    required this.roleCodes,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.employeeId,
    this.employeeName,
    this.unitName,
    this.createdByUserId,
    this.updatedByUserId,
  });

  factory UserAdminResponse.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['role_codes'] as List<dynamic>? ?? const [];
    return UserAdminResponse(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      employeeId: json['employee_id'] as String?,
      employeeName: json['employee_name'] as String?,
      unitName: json['unit_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      roleCodes: rawRoles.map((role) => role as String).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdByUserId: json['created_by_user_id'] as String?,
      updatedByUserId: json['updated_by_user_id'] as String?,
    );
  }

  final String id;
  final String username;
  final String? email;
  final String? employeeId;
  final String? employeeName;
  final String? unitName;
  final bool isActive;
  final List<String> roleCodes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByUserId;
  final String? updatedByUserId;
}

class CreateUserRequest {
  const CreateUserRequest({
    required this.username,
    required this.employeeId,
    required this.initialPassword,
    required this.roleIds,
    this.email,
  });

  final String username;
  final String? email;
  final String employeeId;
  final String initialPassword;
  final List<String> roleIds;

  Map<String, dynamic> toJson() => {
        'username': username,
        if (email != null) 'email': email,
        'employee_id': employeeId,
        'initial_password': initialPassword,
        'role_ids': roleIds,
      };
}

class UpdateUserRequest {
  const UpdateUserRequest({
    required this.username,
    required this.employeeId,
    required this.roleIds,
    this.email,
  });

  final String username;
  final String? email;
  final String employeeId;
  final List<String> roleIds;

  Map<String, dynamic> toJson() => {
        'username': username,
        if (email != null) 'email': email,
        'employee_id': employeeId,
        'role_ids': roleIds,
      };
}

class RoleOptionResponse {
  const RoleOptionResponse({
    required this.id,
    required this.code,
    required this.name,
  });

  factory RoleOptionResponse.fromJson(Map<String, dynamic> json) {
    return RoleOptionResponse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String code;
  final String name;
}
