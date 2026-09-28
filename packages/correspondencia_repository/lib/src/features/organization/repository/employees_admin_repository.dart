import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';

import '../../../core/entities/admin_page.dart';
import '../entities/employee_admin.dart';
import '../mappers/organization_admin_mapper.dart';

class EmployeesAdminRepository {
  EmployeesAdminRepository({required EmployeesAdminApi api}) : _api = api;

  final EmployeesAdminApi _api;

  Future<Result<AdminPage<EmployeeAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
    String? unitId,
    String? positionId,
    bool availableForUser = false,
    String? exceptUserId,
  }) {
    return handleExceptions<AdminPage<EmployeeAdmin>>(
      () async {
        final response = await _api.list(
          page: page,
          pageSize: pageSize,
          search: search,
          isActive: isActive,
          unitId: unitId,
          positionId: positionId,
          availableForUser: availableForUser,
          exceptUserId: exceptUserId,
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
      operation: 'listEmployeesAdmin',
    );
  }

  Future<Result<EmployeeAdmin, Failure>> create(EmployeeInput input) {
    return handleExceptions<EmployeeAdmin>(
      () async => (await _api.create(input.toCreateRequest())).toEntity(),
      feature: 'organization',
      operation: 'createEmployeeAdmin',
    );
  }

  Future<Result<EmployeeAdmin, Failure>> update(
    String id,
    EmployeeInput input,
  ) {
    return handleExceptions<EmployeeAdmin>(
      () async => (await _api.update(id, input.toUpdateRequest())).toEntity(),
      feature: 'organization',
      operation: 'updateEmployeeAdmin',
    );
  }

  Future<Result<EmployeeAdmin, Failure>> setActive(
    String id, {
    required bool isActive,
  }) {
    return handleExceptions<EmployeeAdmin>(
      () async => (await _api.setActive(id, isActive: isActive)).toEntity(),
      feature: 'organization',
      operation: 'setEmployeeActive',
    );
  }
}
