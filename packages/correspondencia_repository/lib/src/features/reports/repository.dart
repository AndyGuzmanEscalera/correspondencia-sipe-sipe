import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';
import 'entities.dart';
import 'mappers.dart';

class ReportFilter {
  const ReportFilter(
      {this.kind = 'registered',
      this.dateFrom,
      this.dateTo,
      this.documentTypeId,
      this.status,
      this.unitId,
      this.employeeId,
      this.search});
  final String kind;
  final String? dateFrom,
      dateTo,
      documentTypeId,
      status,
      unitId,
      employeeId,
      search;
  Map<String, dynamic> toQuery() => {
        'kind': kind,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        if (documentTypeId != null) 'document_type_id': documentTypeId,
        if (status != null) 'status': status,
        if (unitId != null) 'unit_id': unitId,
        if (employeeId != null) 'employee_id': employeeId,
        if (search?.trim().isNotEmpty ?? false) 'search': search!.trim()
      };
}

class ReportsRepository {
  ReportsRepository({required ReportsApi api}) : _api = api;
  final ReportsApi _api;
  Future<Result<ReportOptions, Failure>> options() =>
      handleExceptions(() async => (await _api.options()).toEntity(),
          feature: 'reports', operation: 'options');
  Future<Result<ReportPage, Failure>> list(ReportFilter filter,
          {int page = 1, int pageSize = 20}) =>
      handleExceptions(
          () async => (await _api.list(filter.toQuery(),
                  page: page, pageSize: pageSize))
              .toEntity(),
          feature: 'reports',
          operation: 'list');
  Future<Result<List<int>, Failure>> export(ReportFilter filter) =>
      handleExceptions(() => _api.export(filter.toQuery()),
          feature: 'reports', operation: 'export');
}
