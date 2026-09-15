part of 'correspondence_list_cubit.dart';

class CorrespondenceListState extends Equatable implements StatusState {
  const CorrespondenceListState({
    this.items = const [],
    this.query = '',
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
  });

  final List<CorrespondenceEntity> items;
  final String query;

  @override
  final GeneralStatus generalStatus;

  @override
  final DialogMessage dialogMessage;

  CorrespondenceListState copyWith({
    List<CorrespondenceEntity>? items,
    String? query,
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
  }) {
    return CorrespondenceListState(
      items: items ?? this.items,
      query: query ?? this.query,
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
    );
  }

  @override
  List<Object?> get props => [items, query, generalStatus, dialogMessage];
}
