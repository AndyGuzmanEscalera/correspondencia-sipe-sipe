import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';
import '../entities/institutional_settings.dart';

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
          mayorDisplayName: item.mayorDisplayName,
          mayorEmployeeId: item.mayorEmployeeId,
          mayor: item.mayor == null ? null : _employee(item.mayor!),
          mayorValidationError: item.mayorValidationError);
  Future<Result<InstitutionalSettings, Failure>> getInstitutionalSettings() =>
      handleExceptions(
          () async => _settings(await _api.getInstitutionalSettings()),
          feature: 'systemSettings',
          operation: 'getInstitutionalSettings');
  Future<Result<List<AuthorityEmployee>, Failure>> getAuthorityEmployees() =>
      handleExceptions(
          () async =>
              (await _api.getAuthorityEmployees()).map(_employee).toList(),
          feature: 'systemSettings',
          operation: 'getAuthorityEmployees');
  Future<Result<InstitutionalSettings, Failure>> updateInstitutionalSettings({
    required String? mayorEmployeeId,
  }) =>
      handleExceptions(
          () async => _settings(await _api.updateInstitutionalSettings(
              mayorEmployeeId: mayorEmployeeId)),
          feature: 'systemSettings',
          operation: 'updateInstitutionalSettings');
}
