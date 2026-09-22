import 'package:equatable/equatable.dart';

class UserAdmin extends Equatable {
  const UserAdmin({
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
  });

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

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        employeeId,
        employeeName,
        unitName,
        isActive,
        roleCodes,
        createdAt,
        updatedAt,
      ];
}

class UserCreateInput extends Equatable {
  const UserCreateInput({
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

  @override
  List<Object?> get props =>
      [username, email, employeeId, initialPassword, roleIds];
}

class UserUpdateInput extends Equatable {
  const UserUpdateInput({
    required this.username,
    required this.employeeId,
    required this.roleIds,
    this.email,
  });

  final String username;
  final String? email;
  final String employeeId;
  final List<String> roleIds;

  @override
  List<Object?> get props => [username, email, employeeId, roleIds];
}

class RoleOption extends Equatable {
  const RoleOption({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  @override
  List<Object?> get props => [id, code, name];
}
