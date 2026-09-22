import 'package:correspondencia_repository/correspondencia_repository.dart';

class Permissions {
  const Permissions._();

  static const organizationalUnitsRead = 'master_data.organizational_units.read';
  static const organizationalUnitsManage =
      'master_data.organizational_units.manage';
  static const positionsRead = 'master_data.positions.read';
  static const positionsManage = 'master_data.positions.manage';
  static const employeesRead = 'master_data.employees.read';
  static const employeesManage = 'master_data.employees.manage';
  static const usersRead = 'master_data.users.read';
  static const usersManage = 'master_data.users.manage';
  static const documentTypesRead = 'master_data.document_types.read';
  static const documentTypesManage = 'master_data.document_types.manage';
}

bool hasPermission(UserSession? session, String code) {
  if (session == null) return false;
  return session.permissions.contains(code);
}
