import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/responses.dart';

class ReportsApi {
  ReportsApi({required ApiMethod mainApi}) : _api = mainApi;
  final ApiMethod _api;
  Future<ReportOptionsResponse> options() async =>
      ReportOptionsResponse.fromJson(await _api.get(Endpoints.reportOptions,
          operation: 'reports.options'));
  Future<ReportPageResponse> list(Map<String, dynamic> filters,
          {int page = 1, int pageSize = 20}) async =>
      ReportPageResponse.fromJson(await _api.get(Endpoints.reports,
          queryParameters: {...filters, 'page': page, 'page_size': pageSize},
          operation: 'reports.list'));
  Future<List<int>> export(Map<String, dynamic> filters,
          {String format = 'csv'}) =>
      _api.downloadBytes(
          path: switch (format) {
            'csv' => Endpoints.reportExport,
            'xlsx' => Endpoints.reportExportXlsx,
            'pdf' => Endpoints.reportExportPdf,
            _ => throw ArgumentError.value(format, 'format'),
          },
          queryParameters: filters,
          operation: 'reports.export');
}
