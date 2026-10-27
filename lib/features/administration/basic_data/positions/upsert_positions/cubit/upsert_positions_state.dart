part of 'upsert_positions_cubit.dart';

class UpsertPositionsState extends Equatable implements StatusState {
  const UpsertPositionsState({
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
    this.hierarchies = const [],
    this.hierarchiesLoading = false,
    this.hierarchiesError,
  });

  final List<repo.PositionHierarchy> hierarchies;
  final bool hierarchiesLoading;
  final String? hierarchiesError;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  UpsertPositionsState copyWith({
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
    List<repo.PositionHierarchy>? hierarchies,
    bool? hierarchiesLoading,
    String? hierarchiesError,
    bool clearHierarchiesError = false,
  }) {
    return UpsertPositionsState(
      dialogMessage: dialogMessage ?? this.dialogMessage,
      hierarchies: hierarchies ?? this.hierarchies,
      hierarchiesLoading: hierarchiesLoading ?? this.hierarchiesLoading,
      hierarchiesError: clearHierarchiesError
          ? null
          : hierarchiesError ?? this.hierarchiesError,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        dialogMessage,
        generalStatus,
        hierarchies,
        hierarchiesLoading,
        hierarchiesError
      ];
}
