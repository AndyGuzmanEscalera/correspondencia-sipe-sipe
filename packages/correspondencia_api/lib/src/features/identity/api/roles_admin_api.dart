import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/user_admin_response.dart';

class RolesAdminApi {
  RolesAdminApi({required ApiMethod mainApi}) : _mainApi = mainApi;

  final ApiMethod _mainApi;

  Future<List<RoleOptionResponse>> list() async {
    final items = await _mainApi.getList(
      Endpoints.adminRoles,
      operation: 'admin.roles.list',
    );
    return items.map(RoleOptionResponse.fromJson).toList();
  }
}
