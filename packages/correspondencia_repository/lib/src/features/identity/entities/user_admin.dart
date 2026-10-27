import 'package:equatable/equatable.dart';

class UserAdmin extends Equatable {
  const UserAdmin({
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
  });

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
        directPermissionIds,
        directPermissions,
        effectivePermissions,
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
    this.directPermissionIds,
    this.email,
  });

  final String username;
  final String? email;
  final String employeeId;
  final String initialPassword;
  final List<String>? roleIds;
  final List<String>? directPermissionIds;

  @override
  List<Object?> get props => [
        username,
        email,
        employeeId,
        initialPassword,
        roleIds,
        directPermissionIds
      ];
}

class UserUpdateInput extends Equatable {
  const UserUpdateInput({
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

  @override
  List<Object?> get props =>
      [username, email, employeeId, roleIds, directPermissionIds];
}

class RoleOption extends Equatable {
  const RoleOption({
    this.canAssign = true,
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;
  final bool canAssign;

  @override
  List<Object?> get props => [id, code, name, canAssign];
}

class PermissionOption extends Equatable {
  const PermissionOption(
      {required this.id, required this.code, this.description});
  final String id;
  final String code;
  final String? description;
  bool get isDeprecated => code == 'correspondence.create';

  String get category {
    if (code.startsWith('master_data.')) return 'Administración';
    if (code.startsWith('correspondence.read.')) {
      return 'Correspondencia - Lectura';
    }
    if (code.startsWith('correspondence.create')) {
      return 'Correspondencia - Creación';
    }
    if (code.startsWith('correspondence.')) {
      return 'Correspondencia - Operación';
    }
    if (code.startsWith('reports.')) return 'Reportes';
    if (code.startsWith('system.settings.')) return 'Configuración';
    return 'Otros';
  }

  @override
  List<Object?> get props => [id, code, description];
}
