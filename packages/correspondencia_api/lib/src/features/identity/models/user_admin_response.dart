class UserAdminResponse {
  const UserAdminResponse({
    required this.id,
    required this.username,
    required this.isActive,
    required this.roleCodes,
    this.directPermissionIds = const [],
    this.directPermissions = const [],
    this.effectivePermissions = const [],
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
      directPermissionIds:
          (json['direct_permission_ids'] as List? ?? []).cast<String>(),
      directPermissions:
          (json['direct_permissions'] as List? ?? []).cast<String>(),
      effectivePermissions:
          (json['effective_permissions'] as List? ?? []).cast<String>(),
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
  final List<String> directPermissionIds;
  final List<String> directPermissions;
  final List<String> effectivePermissions;
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
    this.directPermissionIds,
    this.email,
  });

  final String username;
  final String? email;
  final String employeeId;
  final String initialPassword;
  final List<String>? roleIds;
  final List<String>? directPermissionIds;

  Map<String, dynamic> toJson() => {
        'username': username,
        if (email != null) 'email': email,
        'employee_id': employeeId,
        'initial_password': initialPassword,
        if (roleIds != null) 'role_ids': roleIds,
        if (directPermissionIds != null)
          'direct_permission_ids': directPermissionIds,
      };
}

class UpdateUserRequest {
  const UpdateUserRequest({
    required this.username,
    required this.employeeId,
    required this.roleIds,
    this.directPermissionIds,
    this.email,
  });

  final String username;
  final String? email;
  final String employeeId;
  final List<String>? roleIds;
  final List<String>? directPermissionIds;

  Map<String, dynamic> toJson() => {
        'username': username,
        if (email != null) 'email': email,
        'employee_id': employeeId,
        if (roleIds != null) 'role_ids': roleIds,
        if (directPermissionIds != null)
          'direct_permission_ids': directPermissionIds,
      };
}

class RoleOptionResponse {
  const RoleOptionResponse({
    this.canAssign = true,
    required this.id,
    required this.code,
    required this.name,
  });

  factory RoleOptionResponse.fromJson(Map<String, dynamic> json) {
    return RoleOptionResponse(
      canAssign: json['can_assign'] as bool? ?? true,
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String code;
  final String name;
  final bool canAssign;
}

class PermissionOptionResponse {
  const PermissionOptionResponse(
      {required this.id, required this.code, this.description});
  final String id;
  final String code;
  final String? description;
  factory PermissionOptionResponse.fromJson(Map<String, dynamic> json) =>
      PermissionOptionResponse(
          id: json['id'] as String,
          code: json['code'] as String,
          description: json['description'] as String?);
}
