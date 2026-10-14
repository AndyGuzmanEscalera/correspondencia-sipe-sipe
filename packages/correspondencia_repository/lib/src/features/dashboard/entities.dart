class RecentActivity {
  const RecentActivity(
      {required this.id,
      required this.correspondenceId,
      required this.type,
      required this.routeNumber,
      required this.subject,
      required this.createdAt});
  final String id;
  final String correspondenceId;
  final String type;
  final String routeNumber;
  final String subject;
  final DateTime createdAt;
}

class DashboardData {
  const DashboardData(
      {required this.mine,
      required this.unit,
      required this.sent,
      required this.concluded,
      required this.total,
      required this.canViewUnit,
      required this.activity});
  final int mine;
  final int? unit;
  final int sent;
  final int concluded;
  final int total;
  final bool canViewUnit;
  final List<RecentActivity> activity;
}
