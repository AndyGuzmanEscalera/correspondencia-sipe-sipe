import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:failures/failures.dart';

class FakeAuth implements repo.AuthenticationRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

repo.DashboardData dashboardData({bool scope = false, int mine = 2}) =>
    repo.DashboardData(
        mine: mine,
        unit: scope ? 5 : null,
        sent: 8,
        concluded: 3,
        total: 12,
        canViewUnit: scope,
        activity: const []);

class FakeDashboard implements repo.DashboardRepository {
  Result<repo.DashboardData, Failure> result = Ok(dashboardData());
  Future<Result<repo.DashboardData, Failure>>? pending;
  @override
  Future<Result<repo.DashboardData, Failure>> load() async => pending ?? result;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

repo.InternalNotification notification(
        {String id = 'n1',
        bool read = false,
        String? correspondenceId = 'c1'}) =>
    repo.InternalNotification(
        id: id,
        correspondenceId: correspondenceId,
        type: 'ASSIGNED',
        title: 'Recibida HR-QA',
        message: 'Asunto QA',
        isRead: read,
        createdAt: DateTime.utc(2026, 10, 14, 12),
        readAt: read ? DateTime.utc(2026, 10, 14, 13) : null);

class FakeNotifications implements repo.NotificationsRepository {
  List<repo.InternalNotification> items = [notification()];
  final readIds = <String>[];
  int allCalls = 0;
  Failure? failure;
  Future<Result<int, Failure>>? pendingCount;
  @override
  Future<Result<int, Failure>> count() async =>
      pendingCount ?? Ok(items.where((n) => !n.isRead).length);
  @override
  Future<Result<repo.NotificationsPage, Failure>> list({int page = 1}) async =>
      failure != null
          ? Err(failure!)
          : Ok(repo.NotificationsPage(
              items: items,
              total: items.length,
              page: page,
              pageSize: 20,
              totalPages: items.isEmpty ? 0 : 1,
              unread: items.where((n) => !n.isRead).length));
  @override
  Future<Result<int, Failure>> read(String id) async {
    if (failure != null) return Err(failure!);
    readIds.add(id);
    items = items
        .map((n) => notification(
            id: n.id,
            read: n.id == id || n.isRead,
            correspondenceId: n.correspondenceId))
        .toList();
    return Ok(items.where((n) => !n.isRead).length);
  }

  @override
  Future<Result<int, Failure>> readAll() async {
    if (failure != null) return Err(failure!);
    allCalls++;
    items = items
        .map((n) => notification(
            id: n.id, read: true, correspondenceId: n.correspondenceId))
        .toList();
    return const Ok(0);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

repo.ReportPage reportData({bool empty = false, int page = 1}) =>
    repo.ReportPage(
        items: empty
            ? const []
            : [
                repo.ReportRow(
                    id: 'c1',
                    routeNumber: 'HR-QA-1',
                    date: DateTime.utc(2026, 10, 14, 12),
                    documentType: 'NOTA',
                    subject: 'Reporte QA',
                    reference: 'Ref QA',
                    origin: 'Origen QA',
                    destination: 'Destino QA',
                    employee: 'Funcionario QA',
                    status: 'ACTIVE')
              ],
        total: empty ? 0 : 41,
        page: page,
        pageSize: 20,
        totalPages: empty ? 0 : 3,
        summary: repo.ReportSummary(
            total: empty ? 0 : 41,
            pending: empty ? 0 : 40,
            concluded: empty ? 0 : 1,
            byType: const [repo.ReportDistribution(name: 'NOTA', total: 41)],
            byUnit: const []));

class FakeReports implements repo.ReportsRepository {
  repo.ReportOptions configuration = const repo.ReportOptions(
      types: [repo.ReportOption(id: 't1', name: 'NOTA')],
      units: [],
      employees: [],
      canViewUnit: false);
  Result<repo.ReportPage, Failure> result = Ok(reportData());
  Future<Result<repo.ReportPage, Failure>>? pending;
  final calls = <({repo.ReportFilter filter, int page, int size})>[];
  repo.ReportFilter? exported;
  @override
  Future<Result<repo.ReportOptions, Failure>> options() async =>
      Ok(configuration);
  @override
  Future<Result<repo.ReportPage, Failure>> list(repo.ReportFilter filter,
      {int page = 1, int pageSize = 20}) async {
    calls.add((filter: filter, page: page, size: pageSize));
    return pending ?? result;
  }

  @override
  Future<Result<List<int>, Failure>> export(repo.ReportFilter filter) async {
    exported = filter;
    return const Ok([65, 66]);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
