part of 'inbox_entry_cubit.dart';

class InboxEntryState extends Equatable implements StatusState {
  const InboxEntryState({
    this.scope = repo.InboxScope.mine,
    this.items = const [],
    this.query = '',
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.totalPages = 0,
    this.counts = const repo.InboxCounts(mine: 0, unit: 0),
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final repo.InboxScope scope;
  final List<CorrespondenceEntity> items;
  final String query;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final repo.InboxCounts counts;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  InboxEntryState copyWith({
    repo.InboxScope? scope,
    List<CorrespondenceEntity>? items,
    String? query,
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
    repo.InboxCounts? counts,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return InboxEntryState(
      scope: scope ?? this.scope,
      items: items ?? this.items,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      counts: counts ?? this.counts,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        scope,
        items,
        query,
        page,
        pageSize,
        total,
        totalPages,
        counts,
        dialogMessage,
        generalStatus,
      ];
}
