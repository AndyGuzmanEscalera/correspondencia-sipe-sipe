part of 'positions_list_cubit.dart';

class PositionsListState extends Equatable implements StatusState {
  const PositionsListState({
    this.items = const [],
    this.query = '',
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.totalPages = 0,
    this.listLoading = false,
    this.saveInProgress = false,
    this.saveError,
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
  });

  final List<repo.PositionAdmin> items;
  final String query;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool listLoading;
  final bool saveInProgress;
  final String? saveError;

  @override
  final GeneralStatus generalStatus;
  @override
  final DialogMessage dialogMessage;

  PositionsListState copyWith({
    List<repo.PositionAdmin>? items,
    String? query,
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
    bool? listLoading,
    bool? saveInProgress,
    String? saveError,
    bool clearSaveError = false,
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
  }) {
    return PositionsListState(
      items: items ?? this.items,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      listLoading: listLoading ?? this.listLoading,
      saveInProgress: saveInProgress ?? this.saveInProgress,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
    );
  }

  @override
  List<Object?> get props =>
      [
        items,
        query,
        page,
        pageSize,
        total,
        totalPages,
        listLoading,
        saveInProgress,
        saveError,
        generalStatus,
        dialogMessage,
      ];
}
