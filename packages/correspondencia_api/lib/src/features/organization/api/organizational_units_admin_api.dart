import '../../../core/models/active_toggle_request.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/organizational_unit_admin_response.dart';

class OrganizationalUnitsAdminApi {
  OrganizationalUnitsAdminApi({required ApiMethod mainApi}) : _mainApi = mainApi;

  final ApiMethod _mainApi;

  Future<PaginatedResponse<OrganizationalUnitAdminResponse>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    final json = await _mainApi.get(
      Endpoints.adminOrganizationalUnits,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'is_active': isActive,
      },
      operation: 'admin.organizationalUnits.list',
    );
    return PaginatedResponse.fromJson(
      json,
      OrganizationalUnitAdminResponse.fromJson,
    );
  }

  Future<OrganizationalUnitAdminResponse> get(String id) async {
    final json = await _mainApi.get(
      Endpoints.adminOrganizationalUnit(id),
      operation: 'admin.organizationalUnits.get',
    );
    return OrganizationalUnitAdminResponse.fromJson(json);
  }

  Future<OrganizationalUnitAdminResponse> create(
    CreateOrganizationalUnitRequest request,
  ) async {
    final json = await _mainApi.post(
      Endpoints.adminOrganizationalUnits,
      data: request.toJson(),
      operation: 'admin.organizationalUnits.create',
    );
    return OrganizationalUnitAdminResponse.fromJson(json);
  }

  Future<OrganizationalUnitAdminResponse> update(
    String id,
    UpdateOrganizationalUnitRequest request,
  ) async {
    final json = await _mainApi.put(
      Endpoints.adminOrganizationalUnit(id),
      data: request.toJson(),
      operation: 'admin.organizationalUnits.update',
    );
    return OrganizationalUnitAdminResponse.fromJson(json);
  }

  Future<OrganizationalUnitAdminResponse> setActive(
    String id, {
    required bool isActive,
  }) async {
    final json = await _mainApi.patch(
      Endpoints.adminOrganizationalUnitActive(id),
      data: ActiveToggleRequest(isActive: isActive).toJson(),
      operation: 'admin.organizationalUnits.setActive',
    );
    return OrganizationalUnitAdminResponse.fromJson(json);
  }
}
