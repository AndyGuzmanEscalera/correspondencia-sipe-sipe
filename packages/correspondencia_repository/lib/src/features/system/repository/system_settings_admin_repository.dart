import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';
import '../entities/institutional_settings.dart';
import '../../organization/entities/organizational_unit.dart';

class SystemSettingsAdminRepository {
  SystemSettingsAdminRepository({required SystemSettingsAdminApi api})
      : _api = api;
  final SystemSettingsAdminApi _api;
  static AuthorityEmployee _employee(AuthorityEmployeeResponse item) =>
      AuthorityEmployee(
          employeeId: item.employeeId,
          employeeName: item.employeeName,
          positionName: item.positionName,
          unitName: item.unitName,
          documentNumber: item.documentNumber);
  static InstitutionalSettings _settings(InstitutionalSettingsResponse item) =>
      InstitutionalSettings(
          intakeUnitId: item.intakeUnitId,
          intakeUnitName: item.intakeUnitName,
          initialRecipientEmployeeIds: item.initialRecipientEmployeeIds,
          initialRecipients: item.initialRecipients.map(_employee).toList(),
          mayorDisplayName: item.mayorDisplayName,
          mayorEmployeeId: item.mayorEmployeeId,
          mayor: item.mayor == null ? null : _employee(item.mayor!),
          mayorValidationError: item.mayorValidationError);
  Future<Result<InstitutionalSettings, Failure>> getInstitutionalSettings() =>
      handleExceptions(
          () async => _settings(await _api.getInstitutionalSettings()),
          feature: 'systemSettings',
          operation: 'getInstitutionalSettings');
  Future<Result<InstitutionalSettings, Failure>> updateDocumentAuthorityName(
          String name) =>
      handleExceptions(
          () async => _settings(await _api.updateDocumentAuthorityName(name)),
          feature: 'systemSettings',
          operation: 'updateDocumentAuthorityName');

  Future<Result<List<AuthorityEmployee>, Failure>> getAuthorityEmployees() =>
      handleExceptions(
          () async =>
              (await _api.getAuthorityEmployees()).map(_employee).toList(),
          feature: 'systemSettings',
          operation: 'getAuthorityEmployees');
  Future<Result<InstitutionalSettings, Failure>> updateInstitutionalSettings({
    required String? mayorEmployeeId,
    String? mayorDisplayName,
    String? intakeUnitId,
    List<String>? initialRecipientEmployeeIds,
  }) =>
      handleExceptions(
          () async => _settings(await _api.updateInstitutionalSettings(
              mayorEmployeeId: mayorEmployeeId,
              intakeUnitId: intakeUnitId,
              initialRecipientEmployeeIds: initialRecipientEmployeeIds,
              mayorDisplayName: mayorDisplayName)),
          feature: 'systemSettings',
          operation: 'updateInstitutionalSettings');

  Future<Result<List<OrganizationalUnit>, Failure>> getIntakeUnits() => handleExceptions(
      () async => (await _api.getIntakeUnits()).map((x) => OrganizationalUnit(id: x.id, code: x.code, name: x.name)).toList(),
      feature: 'systemSettings', operation: 'getIntakeUnits');
}
