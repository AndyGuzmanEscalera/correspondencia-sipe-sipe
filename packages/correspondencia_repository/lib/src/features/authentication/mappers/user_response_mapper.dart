import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';

/// Maps API DTOs to domain entities.
extension UserResponseToEntity on UserResponse {
  UserSession toEntity() => UserSession(
        id: id,
        username: username,
        isActive: isActive,
        email: email,
        employeeId: employeeId,
        institutionalContext: employee?.toInstitutionalContext(),
        roles: roles,
        permissions: permissions,
      );
}

extension MeEmployeeContextMapping on MeEmployeeContextResponse {
  InstitutionalContext toInstitutionalContext() => InstitutionalContext(
        employeeId: id,
        employeeName: fullName,
        documentNumber: documentNumber,
        positionId: position?.id,
        positionName: position?.name,
        unitId: unit?.id,
        unitName: unit?.name,
      );
}
