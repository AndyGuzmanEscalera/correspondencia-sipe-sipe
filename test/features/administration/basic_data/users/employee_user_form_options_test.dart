import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/helpers/employee_user_form_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime.utc(2026, 1, 1);

  test('employeeToFormOption incluye subtítulo cargo · unidad', () {
    final employee = EmployeeAdmin(
      id: 'e-1',
      firstName: 'Juan',
      lastName: 'Pérez',
      isActive: true,
      createdAt: date,
      updatedAt: date,
      positionName: 'Analista de Sistemas',
      unitName: 'Unidad de Sistemas',
      documentNumber: '1234567',
    );

    final option = employeeToFormOption(employee);

    expect(option.text, 'Juan Pérez');
    expect(option.description, 'Analista de Sistemas · Unidad de Sistemas');
    expect(option.keywords, contains('1234567'));
  });
}
