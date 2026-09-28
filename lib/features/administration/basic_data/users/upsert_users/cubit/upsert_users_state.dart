part of 'upsert_users_cubit.dart';

class UpsertUsersState extends Equatable implements StatusState {
  const UpsertUsersState({
    this.employees = const [],
    this.roles = const [],
    this.catalogLoaded = false,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final List<repo.EmployeeAdmin> employees;
  final List<repo.RoleOption> roles;
  final bool catalogLoaded;

  bool get catalogReady => catalogLoaded && roles.isNotEmpty;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  UpsertUsersState copyWith({
    List<repo.EmployeeAdmin>? employees,
    List<repo.RoleOption>? roles,
    bool? catalogLoaded,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return UpsertUsersState(
      employees: employees ?? this.employees,
      roles: roles ?? this.roles,
      catalogLoaded: catalogLoaded ?? this.catalogLoaded,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        employees,
        roles,
        catalogLoaded,
        dialogMessage,
        generalStatus,
      ];
}
