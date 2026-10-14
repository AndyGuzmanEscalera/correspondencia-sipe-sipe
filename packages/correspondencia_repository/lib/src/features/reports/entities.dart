class ReportOption {
  const ReportOption({required this.id, required this.name});
  final String id;
  final String name;
}

class ReportDistribution {
  const ReportDistribution({required this.name, required this.total});
  final String name;
  final int total;
}

class ReportSummary {
  const ReportSummary(
      {required this.total,
      required this.pending,
      required this.concluded,
      required this.byType,
      required this.byUnit});
  final int total;
  final int pending;
  final int concluded;
  final List<ReportDistribution> byType;
  final List<ReportDistribution> byUnit;
}

class ReportRow {
  const ReportRow(
      {required this.id,
      required this.routeNumber,
      required this.date,
      required this.documentType,
      required this.subject,
      required this.reference,
      required this.origin,
      required this.destination,
      required this.employee,
      required this.status});
  final String id;
  final String routeNumber;
  final DateTime date;
  final String documentType;
  final String subject;
  final String? reference;
  final String origin;
  final String? destination;
  final String? employee;
  final String status;
}

class ReportPage {
  const ReportPage(
      {required this.items,
      required this.total,
      required this.page,
      required this.pageSize,
      required this.totalPages,
      required this.summary});
  final List<ReportRow> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final ReportSummary summary;
}

class ReportOptions {
  const ReportOptions(
      {required this.types,
      required this.units,
      required this.employees,
      required this.canViewUnit});
  final List<ReportOption> types;
  final List<ReportOption> units;
  final List<ReportOption> employees;
  final bool canViewUnit;
}
