part of 'users_cubit.dart';

class UsersState extends Equatable implements StatusState {
  const UsersState({
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

  final repo.UserAdmin? selected;
  final List<repo.UserAdmin> list;
  final String query;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  UsersState copyWith({
    repo.UserAdmin? selected,
    List<repo.UserAdmin>? list,
    String? query,
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return UsersState(
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
