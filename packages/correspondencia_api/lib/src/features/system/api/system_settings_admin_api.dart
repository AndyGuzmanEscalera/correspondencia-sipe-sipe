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
    required String? mayorDisplayName,
  }) async {
    final json = await _mainApi.put(
      Endpoints.adminSystemSettingsInstitutional,
      data: {'mayor_display_name': mayorDisplayName},
      operation: 'systemSettings.updateInstitutional',
    );
    return InstitutionalSettingsResponse.fromJson(json);
  }
}
