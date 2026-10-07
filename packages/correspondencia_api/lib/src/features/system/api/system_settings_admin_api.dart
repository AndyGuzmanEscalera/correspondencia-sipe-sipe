import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/institutional_settings_response.dart';

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

  Future<InstitutionalSettingsResponse> updateInstitutionalSettings({
    required String? mayorEmployeeId,
  }) async {
    final json = await _mainApi.put(
      Endpoints.adminSystemSettingsInstitutional,
      data: {'mayor_employee_id': mayorEmployeeId},
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
}
