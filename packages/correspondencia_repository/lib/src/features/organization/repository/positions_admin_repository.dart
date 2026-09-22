import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';

import '../../../core/entities/admin_page.dart';
import '../entities/position_admin.dart';
import '../mappers/organization_admin_mapper.dart';

class PositionsAdminRepository {
  PositionsAdminRepository({required PositionsAdminApi api}) : _api = api;

  final PositionsAdminApi _api;

  Future<Result<AdminPage<PositionAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) {
    return handleExceptions<AdminPage<PositionAdmin>>(
      () async {
        final response = await _api.list(
          page: page,
          pageSize: pageSize,
          search: search,
          isActive: isActive,
        );
        return AdminPage(
          items: response.items.map((item) => item.toEntity()).toList(),
          page: response.page,
          pageSize: response.pageSize,
          total: response.total,
          totalPages: response.totalPages,
        );
      },
      feature: 'organization',
      operation: 'listPositionsAdmin',
    );
  }

  Future<Result<PositionAdmin, Failure>> create(PositionInput input) {
    return handleExceptions<PositionAdmin>(
      () async => (await _api.create(input.toCreateRequest())).toEntity(),
      feature: 'organization',
      operation: 'createPositionAdmin',
    );
  }

  Future<Result<PositionAdmin, Failure>> update(
    String id,
    PositionInput input,
  ) {
    return handleExceptions<PositionAdmin>(
      () async => (await _api.update(id, input.toUpdateRequest())).toEntity(),
      feature: 'organization',
      operation: 'updatePositionAdmin',
    );
  }

  Future<Result<PositionAdmin, Failure>> setActive(
    String id, {
    required bool isActive,
  }) {
    return handleExceptions<PositionAdmin>(
      () async => (await _api.setActive(id, isActive: isActive)).toEntity(),
      feature: 'organization',
      operation: 'setPositionActive',
    );
  }
}
