import 'package:correspondencia_repository/correspondencia_repository.dart';

class Permissions {
  static const reportsView = 'reports.view';
  const Permissions._();

  static const organizationalUnitsRead =
      'master_data.organizational_units.read';
  static const organizationalUnitsManage =
      'master_data.organizational_units.manage';
  static const positionsRead = 'master_data.positions.read';
  static const positionsManage = 'master_data.positions.manage';
  static const employeesRead = 'master_data.employees.read';
  static const employeesManage = 'master_data.employees.manage';
  static const usersRead = 'master_data.users.read';
  static const usersManage = 'master_data.users.manage';
  static const rolesAssign = 'master_data.roles.assign';
  static const documentTypesRead = 'master_data.document_types.read';
  static const documentTypesManage = 'master_data.document_types.manage';
  static const systemSettingsRead = 'system.settings.read';
  static const systemSettingsManage = 'system.settings.manage';
}

bool hasPermission(UserSession? session, String code) {
  if (session == null) return false;
  return session.permissions.contains(code);
}

const correspondenceCreationPermissions = {
  'correspondence.create.internal_communication',
  'correspondence.create.report',
  'correspondence.create.memorandum',
  'correspondence.create.circular',
};
bool canCreateCorrespondence(Iterable<String> permissions) =>
    permissions.any(correspondenceCreationPermissions.contains);
