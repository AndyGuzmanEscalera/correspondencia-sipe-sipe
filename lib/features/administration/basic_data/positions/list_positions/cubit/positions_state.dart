part of 'positions_cubit.dart';

class PositionsState extends Equatable implements StatusState {
  const PositionsState({
    this.selected,
    this.list = const [],
    this.query = '',
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.totalPages = 0,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final repo.PositionAdmin? selected;
  final List<repo.PositionAdmin> list;
  final String query;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  PositionsState copyWith({
    repo.PositionAdmin? selected,
    List<repo.PositionAdmin>? list,
    String? query,
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return PositionsState(
      selected: selected ?? this.selected,
      list: list ?? this.list,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        selected,
        list,
        query,
        page,
        pageSize,
        total,
        totalPages,
        dialogMessage,
        generalStatus,
      ];
}
