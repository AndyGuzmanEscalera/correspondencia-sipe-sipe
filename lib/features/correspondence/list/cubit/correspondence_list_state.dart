part of 'correspondence_list_cubit.dart';

class CorrespondenceListState extends Equatable implements StatusState {
  const CorrespondenceListState({
    this.items = const [],
    this.documentTypes = const [],
    this.organizationalUnits = const [],
    this.createUnitUsers = const [],
    this.query = '',
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.totalPages = 0,
    this.listLoading = false,
    this.catalogsLoading = false,
    this.unitUsersLoading = false,
    this.createInProgress = false,
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
  });

  final List<CorrespondenceEntity> items;
  final List<repo.DocumentType> documentTypes;
  final List<repo.OrganizationalUnit> organizationalUnits;
  final List<repo.UnitUser> createUnitUsers;
  final String query;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool listLoading;
  final bool catalogsLoading;
  final bool unitUsersLoading;
  final bool createInProgress;

  bool get createCatalogsReady =>
      !catalogsLoading &&
      documentTypes.isNotEmpty &&
      organizationalUnits.isNotEmpty;

  @override
  final GeneralStatus generalStatus;

  @override
  final DialogMessage dialogMessage;

  CorrespondenceListState copyWith({
    List<CorrespondenceEntity>? items,
    List<repo.DocumentType>? documentTypes,
    List<repo.OrganizationalUnit>? organizationalUnits,
    List<repo.UnitUser>? createUnitUsers,
    String? query,
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
    bool? listLoading,
    bool? catalogsLoading,
    bool? unitUsersLoading,
    bool? createInProgress,
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
    bool clearCreateUnitUsers = false,
  }) {
    return CorrespondenceListState(
      items: items ?? this.items,
      documentTypes: documentTypes ?? this.documentTypes,
      organizationalUnits: organizationalUnits ?? this.organizationalUnits,
      createUnitUsers: clearCreateUnitUsers
          ? const []
          : (createUnitUsers ?? this.createUnitUsers),
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      listLoading: listLoading ?? this.listLoading,
      catalogsLoading: catalogsLoading ?? this.catalogsLoading,
      unitUsersLoading: unitUsersLoading ?? this.unitUsersLoading,
      createInProgress: createInProgress ?? this.createInProgress,
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
    );
  }

  @override
  List<Object?> get props => [
        items,
        documentTypes,
        organizationalUnits,
        createUnitUsers,
        query,
        page,
        pageSize,
        total,
        totalPages,
        listLoading,
        catalogsLoading,
        unitUsersLoading,
        createInProgress,
        generalStatus,
        dialogMessage,
      ];
}
