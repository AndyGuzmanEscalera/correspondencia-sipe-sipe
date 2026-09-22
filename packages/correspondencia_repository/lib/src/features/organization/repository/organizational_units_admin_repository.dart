import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';

import '../../../core/entities/admin_page.dart';
import '../entities/organizational_unit_admin.dart';
import '../mappers/organization_admin_mapper.dart';

class OrganizationalUnitsAdminRepository {
  OrganizationalUnitsAdminRepository({
    required OrganizationalUnitsAdminApi api,
  }) : _api = api;

  final OrganizationalUnitsAdminApi _api;

  Future<Result<AdminPage<OrganizationalUnitAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) {
    return handleExceptions<AdminPage<OrganizationalUnitAdmin>>(
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
      operation: 'listOrganizationalUnitsAdmin',
    );
  }

  Future<Result<OrganizationalUnitAdmin, Failure>> create(
    OrganizationalUnitInput input,
  ) {
    return handleExceptions<OrganizationalUnitAdmin>(
      () async => (await _api.create(input.toCreateRequest())).toEntity(),
      feature: 'organization',
      operation: 'createOrganizationalUnitAdmin',
    );
  }

  Future<Result<OrganizationalUnitAdmin, Failure>> update(
    String id,
    OrganizationalUnitInput input,
  ) {
    return handleExceptions<OrganizationalUnitAdmin>(
      () async =>
          (await _api.update(id, input.toUpdateRequest())).toEntity(),
      feature: 'organization',
      operation: 'updateOrganizationalUnitAdmin',
    );
  }

  Future<Result<OrganizationalUnitAdmin, Failure>> setActive(
    String id, {
    required bool isActive,
  }) {
    return handleExceptions<OrganizationalUnitAdmin>(
      () async => (await _api.setActive(id, isActive: isActive)).toEntity(),
      feature: 'organization',
      operation: 'setOrganizationalUnitActive',
    );
  }
}
