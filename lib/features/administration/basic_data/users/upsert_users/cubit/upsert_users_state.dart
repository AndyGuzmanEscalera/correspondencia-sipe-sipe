part of 'upsert_users_cubit.dart';

class UpsertUsersState extends Equatable implements StatusState {
  const UpsertUsersState({
    this.employees = const [],
    this.roles = const [],
    this.permissions = const [],
    this.canManagePermissions = false,
    this.catalogLoaded = false,
    this.catalogReady = false,
    this.canAssignRoles = false,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final List<repo.EmployeeAdmin> employees;
  final List<repo.RoleOption> roles;
  final List<repo.PermissionOption> permissions;
  final bool canManagePermissions;
  final bool catalogLoaded;

  final bool catalogReady;
  final bool canAssignRoles;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  UpsertUsersState copyWith({
    List<repo.EmployeeAdmin>? employees,
    List<repo.RoleOption>? roles,
    List<repo.PermissionOption>? permissions,
    bool? canManagePermissions,
    bool? catalogLoaded,
    bool? catalogReady,
    bool? canAssignRoles,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return UpsertUsersState(
      employees: employees ?? this.employees,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      canManagePermissions: canManagePermissions ?? this.canManagePermissions,
      catalogLoaded: catalogLoaded ?? this.catalogLoaded,
      catalogReady: catalogReady ?? this.catalogReady,
      canAssignRoles: canAssignRoles ?? this.canAssignRoles,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        employees,
        roles,
        permissions,
        canManagePermissions,
        catalogLoaded,
        catalogReady,
        canAssignRoles,
        dialogMessage,
        generalStatus,
      ];
}
