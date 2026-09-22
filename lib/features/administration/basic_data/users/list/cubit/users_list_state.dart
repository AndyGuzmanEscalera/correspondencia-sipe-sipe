part of 'users_list_cubit.dart';

class UsersListState extends Equatable implements StatusState {
  const UsersListState({
    this.items = const [],
    this.employees = const [],
    this.roles = const [],
    this.query = '',
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.totalPages = 0,
    this.listLoading = false,
    this.catalogsLoading = false,
    this.saveInProgress = false,
    this.saveError,
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
  });

  final List<repo.UserAdmin> items;
  final List<repo.EmployeeAdmin> employees;
  final List<repo.RoleOption> roles;
  final String query;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool listLoading;
  final bool catalogsLoading;
  final bool saveInProgress;
  final String? saveError;

  bool get catalogsReady =>
      !catalogsLoading && employees.isNotEmpty && roles.isNotEmpty;

  @override
  final GeneralStatus generalStatus;
  @override
  final DialogMessage dialogMessage;

  UsersListState copyWith({
    List<repo.UserAdmin>? items,
    List<repo.EmployeeAdmin>? employees,
    List<repo.RoleOption>? roles,
    String? query,
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
    bool? listLoading,
    bool? catalogsLoading,
    bool? saveInProgress,
    String? saveError,
    bool clearSaveError = false,
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
  }) {
    return UsersListState(
      items: items ?? this.items,
      employees: employees ?? this.employees,
      roles: roles ?? this.roles,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      listLoading: listLoading ?? this.listLoading,
      catalogsLoading: catalogsLoading ?? this.catalogsLoading,
      saveInProgress: saveInProgress ?? this.saveInProgress,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        employees,
        roles,
        query,
        page,
        pageSize,
        total,
        totalPages,
        listLoading,
        catalogsLoading,
        saveInProgress,
        saveError,
        generalStatus,
        dialogMessage,
      ];
}
