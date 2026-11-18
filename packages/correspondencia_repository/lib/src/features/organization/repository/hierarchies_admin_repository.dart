import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';
import '../../../core/entities/admin_page.dart';
import '../entities/position_admin.dart';

class HierarchiesAdminRepository {
  HierarchiesAdminRepository({required PositionsAdminApi api}) : _api = api;
  final PositionsAdminApi _api;
  static PositionHierarchy _entity(PositionHierarchyResponse row) =>
      PositionHierarchy(
          id: row.id,
          code: row.code,
          name: row.name,
          rank: row.rank,
          isActive: row.isActive);
  static HierarchyRequest _request(HierarchyInput input) => HierarchyRequest(
      code: input.code.trim().toUpperCase(),
      name: input.name.trim(),
      rank: input.rank);
  Future<Result<AdminPage<PositionHierarchy>, Failure>> list(
          {int page = 1,
          int pageSize = 20,
          String? search,
          bool? isActive = true}) =>
      handleExceptions(() async {
        final response = await _api.listHierarchiesAdmin(
            page: page, pageSize: pageSize, search: search, isActive: isActive);
        return AdminPage(
            items: response.items.map(_entity).toList(),
            page: response.page,
            pageSize: response.pageSize,
            total: response.total,
            totalPages: response.totalPages);
      }, feature: 'organization', operation: 'listHierarchies');
  Future<Result<PositionHierarchy, Failure>> get(String id) =>
      handleExceptions(() async => _entity(await _api.getHierarchy(id)),
          feature: 'organization', operation: 'getHierarchy');
  Future<Result<PositionHierarchy, Failure>> create(HierarchyInput input) =>
      handleExceptions(
          () async => _entity(await _api.createHierarchy(_request(input))),
          feature: 'organization',
          operation: 'createHierarchy');
  Future<Result<PositionHierarchy, Failure>> update(
          String id, HierarchyInput input) =>
      handleExceptions(
          () async => _entity(await _api.updateHierarchy(id, _request(input))),
          feature: 'organization',
          operation: 'updateHierarchy');
  Future<Result<PositionHierarchy, Failure>> setActive(String id,
          {required bool isActive}) =>
      handleExceptions(
          () async =>
              _entity(await _api.setHierarchyActive(id, isActive: isActive)),
          feature: 'organization',
          operation: 'setHierarchyActive');
}
