part of 'correspondence_detail_cubit.dart';

class CorrespondenceDetailState extends Equatable implements StatusState {
  const CorrespondenceDetailState({
    this.correspondence,
    this.movements = const [],
    this.viewerUnitId,
    this.lifecycleActionInProgress = false,
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
  });

  final CorrespondenceEntity? correspondence;
  final List<CorrespondenceMovementEntity> movements;
  final String? viewerUnitId;
  final bool lifecycleActionInProgress;

  @override
  final GeneralStatus generalStatus;

  @override
  final DialogMessage dialogMessage;

  bool get canOperateCurrentUnit {
    final item = correspondence;
    if (item == null) return false;
    return item.canOperateCurrentUnit(viewerUnitId);
  }

  CorrespondenceDetailState copyWith({
    CorrespondenceEntity? correspondence,
    List<CorrespondenceMovementEntity>? movements,
    String? viewerUnitId,
    bool? lifecycleActionInProgress,
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
  }) {
    return CorrespondenceDetailState(
      correspondence: correspondence ?? this.correspondence,
      movements: movements ?? this.movements,
      viewerUnitId: viewerUnitId ?? this.viewerUnitId,
      lifecycleActionInProgress:
          lifecycleActionInProgress ?? this.lifecycleActionInProgress,
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
    );
  }

  @override
  List<Object?> get props => [
        correspondence,
        movements,
        viewerUnitId,
        lifecycleActionInProgress,
        generalStatus,
        dialogMessage,
      ];
}
