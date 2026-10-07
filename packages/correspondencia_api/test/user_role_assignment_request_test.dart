import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('C4 create omite role_ids sin asignación', () {
    const request = CreateUserRequest(
        username: 'user',
        employeeId: 'employee',
        initialPassword: 'Secret123',
        roleIds: null);
    expect(request.toJson().containsKey('role_ids'), isFalse);
  });
  test('C4 update distingue omisión de vaciado explícito', () {
    const unchanged = UpdateUserRequest(
        username: 'user', employeeId: 'employee', roleIds: null);
    const cleared = UpdateUserRequest(
        username: 'user', employeeId: 'employee', roleIds: []);
    expect(unchanged.toJson().containsKey('role_ids'), isFalse);
    expect(cleared.toJson()['role_ids'], isEmpty);
  });
  test('C4 create y update conservan IDs cuando se asignan', () {
    const create = CreateUserRequest(
        username: 'user',
        employeeId: 'employee',
        initialPassword: 'Secret123',
        roleIds: ['role']);
    const update = UpdateUserRequest(
        username: 'user', employeeId: 'employee', roleIds: ['role']);
    expect(create.toJson()['role_ids'], ['role']);
    expect(update.toJson()['role_ids'], ['role']);
  });
}
