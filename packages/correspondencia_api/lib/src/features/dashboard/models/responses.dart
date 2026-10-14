class RecentActivityResponse {
  const RecentActivityResponse(
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
  factory RecentActivityResponse.fromJson(Map<String, dynamic> json) =>
      RecentActivityResponse(
        id: json['id'] as String,
        correspondenceId: json['correspondence_id'] as String,
        type: json['type'] as String,
        routeNumber: json['route_number'] as String,
        subject: json['subject'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class DashboardDataResponse {
  const DashboardDataResponse(
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
  final List<RecentActivityResponse> activity;
  factory DashboardDataResponse.fromJson(Map<String, dynamic> json) =>
      DashboardDataResponse(
        mine: (json['mine'] as num).toInt(),
        unit: (json['unit'] as num?)?.toInt(),
        sent: (json['sent'] as num).toInt(),
        concluded: (json['concluded'] as num).toInt(),
        total: (json['total'] as num).toInt(),
        canViewUnit: json['can_view_unit'] as bool,
        activity: (json['activity'] as List)
            .map((item) => RecentActivityResponse.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}
