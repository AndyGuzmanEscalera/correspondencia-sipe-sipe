part of 'dashboard_cubit.dart';

class DashboardState extends Equatable implements StatusState {
  const DashboardState({
    this.mineCount,
    this.unitCount,
    this.sentCount,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final int? mineCount;
  final int? unitCount;
  final int? sentCount;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  String displayCount(int? count, {required bool isLoading}) {
    if (count != null) return '$count';
    if (isLoading) return '…';
    return '—';
  }

  DashboardState copyWith({
    int? mineCount,
    int? unitCount,
    int? sentCount,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return DashboardState(
      mineCount: mineCount ?? this.mineCount,
      unitCount: unitCount ?? this.unitCount,
      sentCount: sentCount ?? this.sentCount,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        mineCount,
        unitCount,
        sentCount,
        dialogMessage,
        generalStatus,
      ];
}
