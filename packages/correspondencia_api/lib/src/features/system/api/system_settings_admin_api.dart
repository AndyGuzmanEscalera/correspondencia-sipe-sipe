import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/institutional_settings_response.dart';
import '../../organization/models/organizational_unit_response.dart';

class SystemSettingsAdminApi {
  SystemSettingsAdminApi({required ApiMethod mainApi}) : _mainApi = mainApi;

  final ApiMethod _mainApi;

  Future<InstitutionalSettingsResponse> getInstitutionalSettings() async {
    final json = await _mainApi.get(
      Endpoints.adminSystemSettingsInstitutional,
      operation: 'systemSettings.getInstitutional',
    );
    return InstitutionalSettingsResponse.fromJson(json);
  }

  Future<InstitutionalSettingsResponse> updateDocumentAuthorityName(
      String name) async {
    final json = await _mainApi.put(
      Endpoints.adminSystemSettingsInstitutional,
      data: {'mayor_display_name': name},
      operation: 'systemSettings.updateDocumentAuthorityName',
    );
    return InstitutionalSettingsResponse.fromJson(json);
  }

  Future<InstitutionalSettingsResponse> updateInstitutionalSettings({
    required String? mayorEmployeeId,
    String? mayorDisplayName,
    String? institutionalEmail,
    String? intakeUnitId,
    List<String>? initialRecipientEmployeeIds,
  }) async {
    final json = await _mainApi.put(
      Endpoints.adminSystemSettingsInstitutional,
      data: {
        'mayor_employee_id': mayorEmployeeId,
        if (mayorDisplayName != null) 'mayor_display_name': mayorDisplayName,
        if (institutionalEmail != null)
          'institutional_email': institutionalEmail,
        if (intakeUnitId != null) 'intake_unit_id': intakeUnitId,
        if (initialRecipientEmployeeIds != null)
          'initial_recipient_employee_ids': initialRecipientEmployeeIds,
      },
      operation: 'systemSettings.updateInstitutional',
    );
    return InstitutionalSettingsResponse.fromJson(json);
  }

  Future<List<AuthorityEmployeeResponse>> getAuthorityEmployees() async {
    final items = await _mainApi.getList(
      Endpoints.adminSystemSettingsAuthorityEmployees,
      operation: 'systemSettings.authorityEmployees',
    );
    return items
        .map((item) => AuthorityEmployeeResponse.fromJson(item))
        .toList();
  }

  Future<List<OrganizationalUnitResponse>> getIntakeUnits() async {
    final rows = await _mainApi.getList('/admin/system-settings/intake-units',
        operation: 'systemSettings.intakeUnits');
    return rows.map(OrganizationalUnitResponse.fromJson).toList();
  }
}
