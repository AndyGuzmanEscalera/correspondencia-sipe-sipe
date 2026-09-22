import '../../../core/models/active_toggle_request.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/position_admin_response.dart';

class PositionsAdminApi {
  PositionsAdminApi({required ApiMethod mainApi}) : _mainApi = mainApi;

  final ApiMethod _mainApi;

  Future<PaginatedResponse<PositionAdminResponse>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    final json = await _mainApi.get(
      Endpoints.adminPositions,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'is_active': isActive,
      },
      operation: 'admin.positions.list',
    );
    return PaginatedResponse.fromJson(json, PositionAdminResponse.fromJson);
  }

  Future<PositionAdminResponse> get(String id) async {
    final json = await _mainApi.get(
      Endpoints.adminPosition(id),
      operation: 'admin.positions.get',
    );
    return PositionAdminResponse.fromJson(json);
  }

  Future<PositionAdminResponse> create(CreatePositionRequest request) async {
    final json = await _mainApi.post(
      Endpoints.adminPositions,
      data: request.toJson(),
      operation: 'admin.positions.create',
    );
    return PositionAdminResponse.fromJson(json);
  }

  Future<PositionAdminResponse> update(
    String id,
    UpdatePositionRequest request,
  ) async {
    final json = await _mainApi.put(
      Endpoints.adminPosition(id),
      data: request.toJson(),
      operation: 'admin.positions.update',
    );
    return PositionAdminResponse.fromJson(json);
  }

  Future<PositionAdminResponse> setActive(
    String id, {
    required bool isActive,
  }) async {
    final json = await _mainApi.patch(
      Endpoints.adminPositionActive(id),
      data: ActiveToggleRequest(isActive: isActive).toJson(),
      operation: 'admin.positions.setActive',
    );
    return PositionAdminResponse.fromJson(json);
  }
}
