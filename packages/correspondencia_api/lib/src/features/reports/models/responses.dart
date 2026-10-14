class ReportOptionResponse {
  const ReportOptionResponse({required this.id, required this.name});
  final String id;
  final String name;
  factory ReportOptionResponse.fromJson(Map<String, dynamic> json) =>
      ReportOptionResponse(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class ReportDistributionResponse {
  const ReportDistributionResponse({required this.name, required this.total});
  final String name;
  final int total;
  factory ReportDistributionResponse.fromJson(Map<String, dynamic> json) =>
      ReportDistributionResponse(
        name: json['name'] as String,
        total: (json['total'] as num).toInt(),
      );
}

class ReportSummaryResponse {
  const ReportSummaryResponse(
      {required this.total,
      required this.pending,
      required this.concluded,
      required this.byType,
      required this.byUnit});
  final int total;
  final int pending;
  final int concluded;
  final List<ReportDistributionResponse> byType;
  final List<ReportDistributionResponse> byUnit;
  factory ReportSummaryResponse.fromJson(Map<String, dynamic> json) =>
      ReportSummaryResponse(
        total: (json['total'] as num).toInt(),
        pending: (json['pending'] as num).toInt(),
        concluded: (json['concluded'] as num).toInt(),
        byType: (json['by_type'] as List)
            .map((item) => ReportDistributionResponse.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
        byUnit: (json['by_unit'] as List)
            .map((item) => ReportDistributionResponse.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class ReportRowResponse {
  const ReportRowResponse(
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
  factory ReportRowResponse.fromJson(Map<String, dynamic> json) =>
      ReportRowResponse(
        id: json['id'] as String,
        routeNumber: json['route_number'] as String,
        date: DateTime.parse(json['date'] as String),
        documentType: json['document_type'] as String,
        subject: json['subject'] as String,
        reference: json['reference'] as String?,
        origin: json['origin'] as String,
        destination: json['destination'] as String?,
        employee: json['employee'] as String?,
        status: json['status'] as String,
      );
}

class ReportPageResponse {
  const ReportPageResponse(
      {required this.items,
      required this.total,
      required this.page,
      required this.pageSize,
      required this.totalPages,
      required this.summary});
  final List<ReportRowResponse> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final ReportSummaryResponse summary;
  factory ReportPageResponse.fromJson(Map<String, dynamic> json) =>
      ReportPageResponse(
        items: (json['items'] as List)
            .map((item) => ReportRowResponse.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
        total: (json['total'] as num).toInt(),
        page: (json['page'] as num).toInt(),
        pageSize: (json['page_size'] as num).toInt(),
        totalPages: (json['total_pages'] as num).toInt(),
        summary: ReportSummaryResponse.fromJson(
            Map<String, dynamic>.from(json['summary'] as Map)),
      );
}

class ReportOptionsResponse {
  const ReportOptionsResponse(
      {required this.types,
      required this.units,
      required this.employees,
      required this.canViewUnit});
  final List<ReportOptionResponse> types;
  final List<ReportOptionResponse> units;
  final List<ReportOptionResponse> employees;
  final bool canViewUnit;
  factory ReportOptionsResponse.fromJson(Map<String, dynamic> json) =>
      ReportOptionsResponse(
        types: (json['types'] as List)
            .map((item) => ReportOptionResponse.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
        units: (json['units'] as List)
            .map((item) => ReportOptionResponse.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
        employees: (json['employees'] as List)
            .map((item) => ReportOptionResponse.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
        canViewUnit: json['can_view_unit'] as bool,
      );
}
