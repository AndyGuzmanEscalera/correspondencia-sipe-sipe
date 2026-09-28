import '../../../core/models/active_toggle_request.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/employee_admin_response.dart';

class EmployeesAdminApi {
  EmployeesAdminApi({required ApiMethod mainApi}) : _mainApi = mainApi;

  final ApiMethod _mainApi;

  Future<PaginatedResponse<EmployeeAdminResponse>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
    String? unitId,
    String? positionId,
    bool availableForUser = false,
    String? exceptUserId,
  }) async {
    final json = await _mainApi.get(
      Endpoints.adminEmployees,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'is_active': isActive,
        if (unitId != null) 'unit_id': unitId,
        if (positionId != null) 'position_id': positionId,
        if (availableForUser) 'available_for_user': true,
        if (exceptUserId != null && exceptUserId.isNotEmpty)
          'except_user_id': exceptUserId,
      },
      operation: 'admin.employees.list',
    );
    return PaginatedResponse.fromJson(json, EmployeeAdminResponse.fromJson);
  }

  Future<EmployeeAdminResponse> get(String id) async {
    final json = await _mainApi.get(
      Endpoints.adminEmployee(id),
      operation: 'admin.employees.get',
    );
    return EmployeeAdminResponse.fromJson(json);
  }

  Future<EmployeeAdminResponse> create(CreateEmployeeRequest request) async {
    final json = await _mainApi.post(
      Endpoints.adminEmployees,
      data: request.toJson(),
      operation: 'admin.employees.create',
    );
    return EmployeeAdminResponse.fromJson(json);
  }

  Future<EmployeeAdminResponse> update(
    String id,
    UpdateEmployeeRequest request,
  ) async {
    final json = await _mainApi.put(
      Endpoints.adminEmployee(id),
      data: request.toJson(),
      operation: 'admin.employees.update',
    );
    return EmployeeAdminResponse.fromJson(json);
  }

  Future<EmployeeAdminResponse> setActive(
    String id, {
    required bool isActive,
  }) async {
    final json = await _mainApi.patch(
      Endpoints.adminEmployeeActive(id),
      data: ActiveToggleRequest(isActive: isActive).toJson(),
      operation: 'admin.employees.setActive',
    );
    return EmployeeAdminResponse.fromJson(json);
  }
}
