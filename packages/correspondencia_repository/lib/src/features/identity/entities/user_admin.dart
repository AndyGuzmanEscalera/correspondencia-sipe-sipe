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
    this.newPassword,
    this.email,
  });

  final String username;
  final String? email;
  final String employeeId;
  final List<String>? roleIds;
  final List<String>? directPermissionIds;
  final String? newPassword;

  @override
  List<Object?> get props =>
      [username, email, employeeId, roleIds, directPermissionIds, newPassword];
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

  String get displayName =>
      const {
        'correspondence.read.own': 'Ver correspondencia propia',
        'correspondence.read.unit': 'Ver correspondencia de su unidad',
        'correspondence.read.all': 'Ver toda la correspondencia',
        'correspondence.create': 'Crear Hoja de Ruta',
        'correspondence.create.internal_communication':
            'Crear comunicado interno',
        'correspondence.create.report': 'Crear informe',
        'correspondence.create.memorandum': 'Crear memorándum',
        'correspondence.create.circular': 'Crear circular',
        'correspondence.derive': 'Derivar correspondencia',
        'correspondence.conclude': 'Concluir correspondencia',
        'correspondence.reopen': 'Reabrir correspondencia',
        'correspondence.attachments.manage': 'Gestionar adjuntos',
        'reports.view': 'Ver reportes',
        'master_data.users.read': 'Ver usuarios',
        'master_data.users.manage': 'Administrar usuarios',
        'master_data.employees.read': 'Ver funcionarios',
        'master_data.employees.manage': 'Administrar funcionarios',
        'master_data.positions.read': 'Ver cargos',
        'master_data.positions.manage': 'Administrar cargos',
        'master_data.organizational_units.read': 'Ver unidades',
        'master_data.organizational_units.manage': 'Administrar unidades',
        'master_data.document_types.read': 'Ver tipos documentales',
        'master_data.document_types.manage': 'Administrar tipos documentales',
        'master_data.roles.assign': 'Asignar roles',
        'system.settings.read': 'Ver configuración institucional',
        'system.settings.manage': 'Modificar configuración institucional',
      }[code] ??
      description ??
      'Permiso institucional';

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
