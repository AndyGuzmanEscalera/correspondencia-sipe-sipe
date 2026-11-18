part of 'upsert_hierarchies_cubit.dart';

class UpsertHierarchiesState extends Equatable implements StatusState {
  const UpsertHierarchiesState(
      {this.generalStatus = GeneralStatus.initial,
      this.dialogMessage = const DialogMessage.empty()});
  @override
  final GeneralStatus generalStatus;
  @override
  final DialogMessage dialogMessage;
  UpsertHierarchiesState copyWith(
          {GeneralStatus? generalStatus, DialogMessage? dialogMessage}) =>
      UpsertHierarchiesState(
          generalStatus: generalStatus ?? this.generalStatus,
          dialogMessage: dialogMessage ?? this.dialogMessage);
  @override
  List<Object?> get props => [generalStatus, dialogMessage];
}
