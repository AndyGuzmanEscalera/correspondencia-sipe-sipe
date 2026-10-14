import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _Reports implements ReportsApi {
  bool fail = false;
  String? exportedFormat;
  @override
  Future<List<int>> export(Map<String, dynamic> filters,
      {String format = 'csv'}) async {
    exportedFormat = format;
    if (fail) throw ServerException(message: 'Error de exportación QA');
    return [80, 75];
  }

  @override
  Future<ReportPageResponse> list(Map<String, dynamic> filters,
      {int page = 1, int pageSize = 20}) async {
    if (fail) throw ServerException(message: 'Safe server error');
    return ReportPageResponse.fromJson({
      'items': [],
      'total': 0,
      'page': page,
      'page_size': pageSize,
      'total_pages': 0,
      'summary': {
        'total': 0,
        'pending': 0,
        'concluded': 0,
        'by_type': [],
        'by_unit': []
      }
    });
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('report filters omit unset values and preserve IDs and search', () {
    const filter = ReportFilter(
        kind: 'sent',
        documentTypeId: 'type',
        employeeId: 'employee',
        dateTo: '2026-10-14',
        search: ' QA ');
    expect(filter.toQuery(), {
      'kind': 'sent',
      'document_type_id': 'type',
      'employee_id': 'employee',
      'date_to': '2026-10-14',
      'search': 'QA'
    });
  });
  test('mapper delivers backend pagination and summary to domain', () async {
    final result = await ReportsRepository(api: _Reports())
        .list(const ReportFilter(), page: 3, pageSize: 50);
    expect(result, isA<Ok<ReportPage, Failure>>());
    final page = (result as Ok<ReportPage, Failure>).value;
    expect(page.page, 3);
    expect(page.pageSize, 50);
    expect(page.summary.total, 0);
    expect(page.items, isEmpty);
  });
  test('server exception remains Result.err ServerFailure', () async {
    final api = _Reports()..fail = true;
    final result = await ReportsRepository(api: api).list(const ReportFilter());
    expect(result, isA<Err<ReportPage, Failure>>());
    result.when(
        ok: (_) => fail('Unexpected success'),
        err: (failure) => expect(failure, isA<ServerFailure>()));
  });
  for (final format in ReportFormat.values) {
    test('repository export ${format.extension} y Failure pipeline', () async {
      final api = _Reports();
      final repository = ReportsRepository(api: api);
      final result =
          await repository.export(const ReportFilter(), format: format);
      expect(api.exportedFormat, format.extension);
      expect(result.valueOrNull(), [80, 75]);
      api.fail = true;
      final failure =
          await repository.export(const ReportFilter(), format: format);
      expect(failure, isA<Err<List<int>, Failure>>());
    });
  }
}
