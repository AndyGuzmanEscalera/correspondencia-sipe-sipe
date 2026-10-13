import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api extends Fake implements SystemSettingsAdminApi {
  String? saved;
  String? savedText;
  bool fail = false;
  final response = const InstitutionalSettingsResponse(
      mayorEmployeeId: 'employee-a',
      mayor: AuthorityEmployeeResponse(
          employeeId: 'employee-a',
          employeeName: 'Autoridad',
          positionName: 'Cargo',
          unitName: 'Unidad',
          documentNumber: '123'));
  @override
  Future<InstitutionalSettingsResponse> getInstitutionalSettings() async =>
      response;
  @override
  Future<List<AuthorityEmployeeResponse>> getAuthorityEmployees() async =>
      [response.mayor!];
  @override
  Future<InstitutionalSettingsResponse> updateInstitutionalSettings(
      {required String? mayorEmployeeId,
      String? mayorDisplayName,
      String? intakeUnitId,
      List<String>? initialRecipientEmployeeIds}) async {
    saved = mayorEmployeeId;
    savedText = mayorDisplayName;
    if (fail) throw ValidationException('Funcionario inactivo');
    return response;
  }
}

void main() {
  test('repository conserva ID, nombre, cargo, unidad y CI', () async {
    final api = _Api();
    final repository = SystemSettingsAdminRepository(api: api);
    final settings =
        (await repository.getInstitutionalSettings()).valueOrNull()!;
    expect(settings.mayorEmployeeId, 'employee-a');
    expect(settings.mayor!.documentNumber, '123');
    expect((await repository.getAuthorityEmployees()).valueOrNull()!.single,
        settings.mayor);
    await repository.updateInstitutionalSettings(
        mayorEmployeeId: 'employee-a', mayorDisplayName: 'Texto institucional');
    expect(api.saved, 'employee-a');
    expect(api.savedText, 'Texto institucional');
  });
  test('repository traduce rechazo de configuración a ValidationFailure',
      () async {
    final repository = SystemSettingsAdminRepository(api: _Api()..fail = true);
    final result = await repository.updateInstitutionalSettings(
        mayorEmployeeId: 'employee-a');
    expect(result.failureOrNull(), isA<ValidationFailure>());
    expect(result.failureOrNull()!.message, 'Funcionario inactivo');
  });
}
