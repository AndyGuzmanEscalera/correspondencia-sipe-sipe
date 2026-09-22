part of 'correspondence_detail_cubit.dart';

class CorrespondenceDetailState extends Equatable implements StatusState {
  const CorrespondenceDetailState({
    this.correspondence,
    this.movements = const [],
    this.organizationalUnits = const [],
    this.unitUsers = const [],
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
  });

  final CorrespondenceEntity? correspondence;
  final List<CorrespondenceMovementEntity> movements;
  final List<repo.OrganizationalUnit> organizationalUnits;
  final List<repo.UnitUser> unitUsers;

  @override
  final GeneralStatus generalStatus;

  @override
  final DialogMessage dialogMessage;

  CorrespondenceDetailState copyWith({
    CorrespondenceEntity? correspondence,
    List<CorrespondenceMovementEntity>? movements,
    List<repo.OrganizationalUnit>? organizationalUnits,
    List<repo.UnitUser>? unitUsers,
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
  }) {
    return CorrespondenceDetailState(
      correspondence: correspondence ?? this.correspondence,
      movements: movements ?? this.movements,
      organizationalUnits: organizationalUnits ?? this.organizationalUnits,
      unitUsers: unitUsers ?? this.unitUsers,
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
    );
  }

  @override
  List<Object?> get props => [
        correspondence,
        movements,
        organizationalUnits,
        unitUsers,
        generalStatus,
        dialogMessage,
      ];
}
