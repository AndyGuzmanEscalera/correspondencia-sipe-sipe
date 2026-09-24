part of 'correspondence_detail_cubit.dart';

class CorrespondenceDetailState extends Equatable implements StatusState {
  const CorrespondenceDetailState({
    this.correspondence,
    this.movements = const [],
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
  });

  final CorrespondenceEntity? correspondence;
  final List<CorrespondenceMovementEntity> movements;

  @override
  final GeneralStatus generalStatus;

  @override
  final DialogMessage dialogMessage;

  CorrespondenceDetailState copyWith({
    CorrespondenceEntity? correspondence,
    List<CorrespondenceMovementEntity>? movements,
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
  }) {
    return CorrespondenceDetailState(
      correspondence: correspondence ?? this.correspondence,
      movements: movements ?? this.movements,
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
    );
  }

  @override
  List<Object?> get props => [
        correspondence,
        movements,
        generalStatus,
        dialogMessage,
      ];
}
