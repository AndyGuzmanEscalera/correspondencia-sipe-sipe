import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserResponse maps institutional employee context', () {
    const response = UserResponse(
      id: 'u-1',
      username: 'mlopez',
      isActive: true,
      employeeId: 'e-1',
      employee: MeEmployeeContextResponse(
        id: 'e-1',
        fullName: 'María López',
        documentNumber: '1234567',
        position: MeInstitutionalPositionResponse(
          id: 'p-1',
          name: 'Secretaria de Secretaría Técnica',
        ),
        unit: MeInstitutionalUnitResponse(
          id: 'u-org',
          name: 'Secretaría Técnica',
        ),
      ),
    );

    final session = response.toEntity();

    expect(session.institutionalContext, isNotNull);
    expect(session.institutionalContext!.employeeName, 'María López');
    expect(session.institutionalContext!.unitId, 'u-org');
    expect(session.institutionalContext!.desktopSubtitle,
        'Secretaria de Secretaría Técnica · Secretaría Técnica');
  });

  test('UserResponse without employee leaves institutionalContext null', () {
    const response = UserResponse(
      id: 'admin',
      username: 'admin',
      isActive: true,
    );

    final session = response.toEntity();

    expect(session.institutionalContext, isNull);
    expect(session.employeeId, isNull);
  });

  test('UserResponse fromJson parses nested employee', () {
    final session = UserResponse.fromJson({
      'id': 'u-1',
      'username': 'jperez',
      'is_active': true,
      'employee_id': 'e-1',
      'employee': {
        'id': 'e-1',
        'full_name': 'Juan Pérez',
        'document_number': '999',
        'position': {'id': 'p-1', 'name': 'Analista'},
        'unit': {'id': 'ou-1', 'name': 'Sistemas'},
      },
      'roles': ['OPERATOR'],
      'permissions': [],
    }).toEntity();

    expect(session.institutionalContext?.employeeName, 'Juan Pérez');
    expect(session.institutionalContext?.positionName, 'Analista');
    expect(session.roles, ['OPERATOR']);
  });
}
