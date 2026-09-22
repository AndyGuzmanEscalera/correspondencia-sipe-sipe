import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/organizational_unit_response.dart';
import '../models/unit_user_response.dart';

class OrganizationApi {
  OrganizationApi({required ApiMethod mainApi}) : _mainApi = mainApi;

  final ApiMethod _mainApi;

  Future<List<OrganizationalUnitResponse>> listUnits() async {
    final items = await _mainApi.getList(
      Endpoints.organizationalUnits,
      operation: 'organization.units',
    );
    return items.map(OrganizationalUnitResponse.fromJson).toList();
  }

  Future<List<UnitUserResponse>> listUnitUsers(String unitId) async {
    final items = await _mainApi.getList(
      Endpoints.organizationalUnitUsers(unitId),
      operation: 'organization.unitUsers',
    );
    return items.map(UnitUserResponse.fromJson).toList();
  }
}
