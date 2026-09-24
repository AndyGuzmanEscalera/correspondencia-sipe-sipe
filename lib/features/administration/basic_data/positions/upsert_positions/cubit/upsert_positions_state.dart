part of 'upsert_positions_cubit.dart';

class UpsertPositionsState extends Equatable implements StatusState {
  const UpsertPositionsState({
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  UpsertPositionsState copyWith({
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return UpsertPositionsState(
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [dialogMessage, generalStatus];
}
