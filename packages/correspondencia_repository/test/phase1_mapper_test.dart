import 'package:correspondencia_api/correspondencia_api.dart' as api;
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_repository/src/features/identity/mappers/identity_admin_mapper.dart';
import 'package:correspondencia_repository/src/features/organization/mappers/organization_admin_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user mapper preserves direct and effective grants separately', () {
    final dto = api.UserAdminResponse(
        id: 'u',
        username: 'user',
        isActive: true,
        roleCodes: const ['OPERADOR'],
        directPermissionIds: const ['p'],
        directPermissions: const ['reports.view'],
        effectivePermissions: const ['reports.view', 'correspondence.create'],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026));
    final entity = dto.toEntity();
    expect(entity.directPermissionIds, ['p']);
    expect(
        entity.effectivePermissions, ['reports.view', 'correspondence.create']);
    expect(
        const UserUpdateInput(
            username: 'u',
            employeeId: 'e',
            roleIds: null,
            directPermissionIds: []).toUpdateRequest().directPermissionIds,
        isEmpty);
  });
  test('position mapper preserves hierarchy and independent scope flag', () {
    final dto = api.PositionAdminResponse(
        id: 'p',
        name: 'Cargo',
        isActive: true,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        hierarchyId: 'h',
        hierarchyCode: 'JEFE',
        hierarchyName: 'Jefe',
        canViewUnitCorrespondence: true);
    final entity = dto.toEntity();
    expect(entity.hierarchyCode, 'JEFE');
    expect(entity.canViewUnitCorrespondence, isTrue);
    expect(
        const PositionInput(code: 'P', name: 'Cargo', hierarchyId: 'h')
            .toCreateRequest()
            .hierarchyId,
        'h');
  });
}
