import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hierarchy metadata round trip and nullable assignment', () {
    final row = PositionAdminResponse.fromJson({
      'id': 'position',
      'name': 'Cargo',
      'created_at': '2026-10-26T00:00:00Z',
      'updated_at': '2026-10-26T00:00:00Z',
      'hierarchy_id': 'hierarchy',
      'hierarchy_code': 'DIRECTOR',
      'hierarchy_name': 'Director'
    });
    expect(row.hierarchyId, 'hierarchy');
    expect(row.hierarchyCode, 'DIRECTOR');
    expect(
        const CreatePositionRequest(code: 'P', name: 'Cargo')
            .toJson()['hierarchy_id'],
        isNull);
    expect(
        const UpdatePositionRequest(
                code: 'P', name: 'Cargo', hierarchyId: 'hierarchy')
            .toJson()['hierarchy_id'],
        'hierarchy');
  });
  test('permission update distinguishes omission from explicit clearing', () {
    expect(
        const UpdateUserRequest(
                username: 'user', employeeId: 'employee', roleIds: null)
            .toJson()
            .containsKey('direct_permission_ids'),
        isFalse);
    expect(
        const UpdateUserRequest(
            username: 'user',
            employeeId: 'employee',
            roleIds: null,
            directPermissionIds: []).toJson()['direct_permission_ids'],
        isEmpty);
    expect(
        const CreateUserRequest(
            username: 'user',
            employeeId: 'employee',
            initialPassword: 'not-a-real-password',
            roleIds: [],
            directPermissionIds: ['p']).toJson()['direct_permission_ids'],
        ['p']);
  });
  test('role assignability defaults compatible and accepts backend restriction',
      () {
    expect(
        RoleOptionResponse.fromJson({
          'id': 'r',
          'code': 'SUPERADMIN',
          'name': 'Superadmin',
          'can_assign': false
        }).canAssign,
        isFalse);
    expect(
        RoleOptionResponse.fromJson(
            {'id': 'r', 'code': 'ADMIN', 'name': 'Admin'}).canAssign,
        isTrue);
  });
}
