import '../../../core/models/active_toggle_request.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/user_admin_response.dart';

class UsersAdminApi {
  UsersAdminApi({required ApiMethod mainApi}) : _mainApi = mainApi;

  final ApiMethod _mainApi;

  Future<List<PermissionOptionResponse>> listPermissions() async {
    final items = await _mainApi.getList('/admin/permissions',
        operation: 'admin.permissions.list');
    return items.map(PermissionOptionResponse.fromJson).toList();
  }

  Future<PaginatedResponse<UserAdminResponse>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive = true,
    String? unitId,
  }) async {
    final json = await _mainApi.get(
      Endpoints.adminUsers,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'is_active': isActive,
        if (isActive == null) 'include_deleted': true,
        if (unitId != null) 'unit_id': unitId,
      },
      operation: 'admin.users.list',
    );
    return PaginatedResponse.fromJson(json, UserAdminResponse.fromJson);
  }

  Future<UserAdminResponse> get(String id) async {
    final json = await _mainApi.get(
      Endpoints.adminUser(id),
      operation: 'admin.users.get',
    );
    return UserAdminResponse.fromJson(json);
  }

  Future<UserAdminResponse> create(CreateUserRequest request) async {
    final json = await _mainApi.post(
      Endpoints.adminUsers,
      data: request.toJson(),
      operation: 'admin.users.create',
    );
    return UserAdminResponse.fromJson(json);
  }

  Future<UserAdminResponse> update(String id, UpdateUserRequest request) async {
    final json = await _mainApi.put(
      Endpoints.adminUser(id),
      data: request.toJson(),
      operation: 'admin.users.update',
    );
    return UserAdminResponse.fromJson(json);
  }

  Future<UserAdminResponse> setActive(
    String id, {
    required bool isActive,
  }) async {
    final json = await _mainApi.patch(
      Endpoints.adminUserActive(id),
      data: ActiveToggleRequest(isActive: isActive).toJson(),
      operation: 'admin.users.setActive',
    );
    return UserAdminResponse.fromJson(json);
  }
}
