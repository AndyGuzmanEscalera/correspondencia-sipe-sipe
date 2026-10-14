part of 'dashboard_cubit.dart';

class DashboardState extends Equatable implements StatusState {
  const DashboardState(
      {this.mineCount,
      this.unitCount,
      this.sentCount,
      this.concludedCount,
      this.totalCount,
      this.canViewUnit = false,
      this.activity = const [],
      this.dialogMessage = const DialogMessage.empty(),
      this.generalStatus = GeneralStatus.initial});
  final int? mineCount, unitCount, sentCount, concludedCount, totalCount;
  final bool canViewUnit;
  final List<repo.RecentActivity> activity;
  @override
  final DialogMessage dialogMessage;
  @override
  final GeneralStatus generalStatus;
  String displayCount(int? count, {required bool isLoading}) => count != null
      ? '$count'
      : isLoading
          ? '…'
          : '—';
  DashboardState copyWith(
          {GeneralStatus? generalStatus, DialogMessage? dialogMessage}) =>
      DashboardState(
          mineCount: mineCount,
          unitCount: unitCount,
          sentCount: sentCount,
          concludedCount: concludedCount,
          totalCount: totalCount,
          canViewUnit: canViewUnit,
          activity: activity,
          generalStatus: generalStatus ?? this.generalStatus,
          dialogMessage: dialogMessage ?? this.dialogMessage);
  @override
  List<Object?> get props => [
        mineCount,
        unitCount,
        sentCount,
        concludedCount,
        totalCount,
        canViewUnit,
        activity,
        generalStatus,
        dialogMessage
      ];
}
