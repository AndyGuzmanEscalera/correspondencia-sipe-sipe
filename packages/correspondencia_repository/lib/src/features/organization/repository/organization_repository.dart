import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';

import '../entities/organizational_unit.dart';
import '../mappers/organization_mapper.dart';

class OrganizationRepository {
  OrganizationRepository({required OrganizationApi organizationApi})
      : _organizationApi = organizationApi;

  final OrganizationApi _organizationApi;

  Future<Result<List<OrganizationalUnit>, Failure>> listActiveUnits() {
    return handleExceptions<List<OrganizationalUnit>>(
      () async {
        final items = await _organizationApi.listUnits();
        return items.map((item) => item.toEntity()).toList();
      },
      feature: 'organization',
      operation: 'listActiveUnits',
    );
  }

  Future<Result<List<UnitUser>, Failure>> listUsersByUnit(String unitId) {
    return handleExceptions<List<UnitUser>>(
      () async {
        final items = await _organizationApi.listUnitUsers(unitId);
        return items.map((item) => item.toEntity()).toList();
      },
      feature: 'organization',
      operation: 'listUsersByUnit',
    );
  }
}
