import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';

import '../entities/institutional_settings.dart';

class SystemSettingsAdminRepository {
  SystemSettingsAdminRepository({required SystemSettingsAdminApi api}) : _api = api;

  final SystemSettingsAdminApi _api;

  Future<Result<InstitutionalSettings, Failure>> getInstitutionalSettings() {
    return handleExceptions<InstitutionalSettings>(
      () async {
        final item = await _api.getInstitutionalSettings();
        return InstitutionalSettings(mayorDisplayName: item.mayorDisplayName);
      },
      feature: 'systemSettings',
      operation: 'getInstitutionalSettings',
    );
  }

  Future<Result<InstitutionalSettings, Failure>> updateInstitutionalSettings({
    required String? mayorDisplayName,
  }) {
    return handleExceptions<InstitutionalSettings>(
      () async {
        final item = await _api.updateInstitutionalSettings(
          mayorDisplayName: mayorDisplayName,
        );
        return InstitutionalSettings(mayorDisplayName: item.mayorDisplayName);
      },
      feature: 'systemSettings',
      operation: 'updateInstitutionalSettings',
    );
  }
}
