part of 'sent_entry_cubit.dart';

class SentEntryState extends Equatable implements StatusState {
  const SentEntryState({
    this.items = const [],
    this.query = '',
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.totalPages = 0,
    this.sentCount = 0,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final List<CorrespondenceEntity> items;
  final String query;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final int sentCount;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  SentEntryState copyWith({
    List<CorrespondenceEntity>? items,
    String? query,
    int? page,
    int? pageSize,
    int? total,
    int? totalPages,
    int? sentCount,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return SentEntryState(
      items: items ?? this.items,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      sentCount: sentCount ?? this.sentCount,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        items,
        query,
        page,
        pageSize,
        total,
        totalPages,
        sentCount,
        dialogMessage,
        generalStatus,
      ];
}
