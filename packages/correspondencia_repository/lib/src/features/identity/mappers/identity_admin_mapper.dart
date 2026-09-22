import 'package:correspondencia_api/correspondencia_api.dart';

import '../entities/user_admin.dart';

extension UserAdminResponseMapper on UserAdminResponse {
  UserAdmin toEntity() => UserAdmin(
        id: id,
        username: username,
        email: email,
        employeeId: employeeId,
        employeeName: employeeName,
        unitName: unitName,
        isActive: isActive,
        roleCodes: roleCodes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension UserCreateInputMapper on UserCreateInput {
  CreateUserRequest toCreateRequest() => CreateUserRequest(
        username: username,
        email: email,
        employeeId: employeeId,
        initialPassword: initialPassword,
        roleIds: roleIds,
      );
}

extension UserUpdateInputMapper on UserUpdateInput {
  UpdateUserRequest toUpdateRequest() => UpdateUserRequest(
        username: username,
        email: email,
        employeeId: employeeId,
        roleIds: roleIds,
      );
}

extension RoleOptionResponseMapper on RoleOptionResponse {
  RoleOption toEntity() => RoleOption(id: id, code: code, name: name);
}
