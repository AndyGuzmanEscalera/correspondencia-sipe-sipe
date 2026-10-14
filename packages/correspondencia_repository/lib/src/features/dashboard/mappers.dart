import 'package:correspondencia_api/correspondencia_api.dart' as api;
import 'entities.dart';

extension RecentActivityMapping on api.RecentActivityResponse {
  RecentActivity toEntity() => RecentActivity(
        id: id,
        correspondenceId: correspondenceId,
        type: type,
        routeNumber: routeNumber,
        subject: subject,
        createdAt: createdAt,
      );
}

extension DashboardDataMapping on api.DashboardDataResponse {
  DashboardData toEntity() => DashboardData(
        mine: mine,
        unit: unit,
        sent: sent,
        concluded: concluded,
        total: total,
        canViewUnit: canViewUnit,
        activity: activity.map((item) => item.toEntity()).toList(),
      );
}
