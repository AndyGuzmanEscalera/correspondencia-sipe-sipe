part of 'employees_list_cubit.dart';

class EmployeesListState extends Equatable implements StatusState {
  const EmployeesListState({
    this.items = const [],
    this.units = const [],
    this.positions = const [],
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

  final List<repo.EmployeeAdmin> items;
  final List<repo.OrganizationalUnitAdmin> units;
  final List<repo.PositionAdmin> positions;
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
      !catalogsLoading && units.isNotEmpty && positions.isNotEmpty;

  @override
  final GeneralStatus generalStatus;
  @override
  final DialogMessage dialogMessage;

  EmployeesListState copyWith({
    List<repo.EmployeeAdmin>? items,
    List<repo.OrganizationalUnitAdmin>? units,
    List<repo.PositionAdmin>? positions,
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
    return EmployeesListState(
      items: items ?? this.items,
      units: units ?? this.units,
      positions: positions ?? this.positions,
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
        units,
        positions,
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
