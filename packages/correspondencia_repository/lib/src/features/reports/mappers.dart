import 'package:correspondencia_api/correspondencia_api.dart' as api;
import 'entities.dart';

extension ReportOptionMapping on api.ReportOptionResponse {
  ReportOption toEntity() => ReportOption(
        id: id,
        name: name,
      );
}

extension ReportDistributionMapping on api.ReportDistributionResponse {
  ReportDistribution toEntity() => ReportDistribution(
        name: name,
        total: total,
      );
}

extension ReportSummaryMapping on api.ReportSummaryResponse {
  ReportSummary toEntity() => ReportSummary(
        total: total,
        pending: pending,
        concluded: concluded,
        byType: byType.map((item) => item.toEntity()).toList(),
        byUnit: byUnit.map((item) => item.toEntity()).toList(),
      );
}

extension ReportRowMapping on api.ReportRowResponse {
  ReportRow toEntity() => ReportRow(
        id: id,
        routeNumber: routeNumber,
        date: date,
        documentType: documentType,
        subject: subject,
        reference: reference,
        origin: origin,
        destination: destination,
        employee: employee,
        status: status,
      );
}

extension ReportPageMapping on api.ReportPageResponse {
  ReportPage toEntity() => ReportPage(
        items: items.map((item) => item.toEntity()).toList(),
        total: total,
        page: page,
        pageSize: pageSize,
        totalPages: totalPages,
        summary: summary.toEntity(),
      );
}

extension ReportOptionsMapping on api.ReportOptionsResponse {
  ReportOptions toEntity() => ReportOptions(
        types: types.map((item) => item.toEntity()).toList(),
        units: units.map((item) => item.toEntity()).toList(),
        employees: employees.map((item) => item.toEntity()).toList(),
        canViewUnit: canViewUnit,
      );
}
