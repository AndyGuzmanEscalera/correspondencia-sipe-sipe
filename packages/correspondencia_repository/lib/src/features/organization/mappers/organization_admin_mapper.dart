import 'package:correspondencia_api/correspondencia_api.dart';

import '../entities/employee_admin.dart';
import '../entities/organizational_unit_admin.dart';
import '../entities/position_admin.dart';

extension OrganizationalUnitAdminResponseMapper
    on OrganizationalUnitAdminResponse {
  OrganizationalUnitAdmin toEntity() => OrganizationalUnitAdmin(
        id: id,
        code: code,
        name: name,
        description: description,
        parentId: parentId,
        parentName: parentName,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension OrganizationalUnitInputMapper on OrganizationalUnitInput {
  CreateOrganizationalUnitRequest toCreateRequest() =>
      CreateOrganizationalUnitRequest(
        code: code,
        name: name,
        description: description,
        parentId: parentId,
      );

  UpdateOrganizationalUnitRequest toUpdateRequest() =>
      UpdateOrganizationalUnitRequest(
        code: code,
        name: name,
        description: description,
        parentId: parentId,
      );
}

extension PositionAdminResponseMapper on PositionAdminResponse {
  PositionAdmin toEntity() => PositionAdmin(
        id: id,
        code: code,
        name: name,
        description: description,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension PositionInputMapper on PositionInput {
  CreatePositionRequest toCreateRequest() => CreatePositionRequest(
        code: code,
        name: name,
        description: description,
      );

  UpdatePositionRequest toUpdateRequest() => UpdatePositionRequest(
        code: code,
        name: name,
        description: description,
      );
}

extension EmployeeAdminResponseMapper on EmployeeAdminResponse {
  EmployeeAdmin toEntity() => EmployeeAdmin(
        id: id,
        firstName: firstName,
        lastName: lastName,
        documentNumber: documentNumber,
        email: email,
        phone: phone,
        unitId: unitId,
        unitName: unitName,
        positionId: positionId,
        positionName: positionName,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension EmployeeInputMapper on EmployeeInput {
  CreateEmployeeRequest toCreateRequest() => CreateEmployeeRequest(
        firstName: firstName,
        lastName: lastName,
        documentNumber: documentNumber,
        email: email,
        phone: phone,
        unitId: unitId,
        positionId: positionId,
      );

  UpdateEmployeeRequest toUpdateRequest() => UpdateEmployeeRequest(
        firstName: firstName,
        lastName: lastName,
        documentNumber: documentNumber,
        email: email,
        phone: phone,
        unitId: unitId,
        positionId: positionId,
      );
}
