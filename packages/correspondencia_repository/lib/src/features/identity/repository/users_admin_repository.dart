import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';

import '../../../core/entities/admin_page.dart';
import '../entities/user_admin.dart';
import '../mappers/identity_admin_mapper.dart';

class UsersAdminRepository {
  UsersAdminRepository({
    required UsersAdminApi usersApi,
    required RolesAdminApi rolesApi,
  })  : _usersApi = usersApi,
        _rolesApi = rolesApi;

  final UsersAdminApi _usersApi;
  final RolesAdminApi _rolesApi;

  Future<Result<AdminPage<UserAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
    String? unitId,
  }) {
    return handleExceptions<AdminPage<UserAdmin>>(
      () async {
        final response = await _usersApi.list(
          page: page,
          pageSize: pageSize,
          search: search,
          isActive: isActive,
          unitId: unitId,
        );
        return AdminPage(
          items: response.items.map((item) => item.toEntity()).toList(),
          page: response.page,
          pageSize: response.pageSize,
          total: response.total,
          totalPages: response.totalPages,
        );
      },
      feature: 'identity',
      operation: 'listUsersAdmin',
    );
  }

  Future<Result<List<RoleOption>, Failure>> listRoles() {
    return handleExceptions<List<RoleOption>>(
      () async {
        final items = await _rolesApi.list();
        return items.map((item) => item.toEntity()).toList();
      },
      feature: 'identity',
      operation: 'listRolesAdmin',
    );
  }

  Future<Result<UserAdmin, Failure>> create(UserCreateInput input) {
    return handleExceptions<UserAdmin>(
      () async => (await _usersApi.create(input.toCreateRequest())).toEntity(),
      feature: 'identity',
      operation: 'createUserAdmin',
    );
  }

  Future<Result<UserAdmin, Failure>> update(
    String id,
    UserUpdateInput input,
  ) {
    return handleExceptions<UserAdmin>(
      () async => (await _usersApi.update(id, input.toUpdateRequest())).toEntity(),
      feature: 'identity',
      operation: 'updateUserAdmin',
    );
  }

  Future<Result<UserAdmin, Failure>> setActive(
    String id, {
    required bool isActive,
  }) {
    return handleExceptions<UserAdmin>(
      () async => (await _usersApi.setActive(id, isActive: isActive)).toEntity(),
      feature: 'identity',
      operation: 'setUserActive',
    );
  }
}
