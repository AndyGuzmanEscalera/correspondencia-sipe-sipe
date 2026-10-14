import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api implements ApiMethod {
  Map<String, dynamic> response = {};
  String? path;
  Map<String, dynamic>? query;
  int posts = 0;
  @override
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters, String? operation}) async {
    this.path = path;
    query = queryParameters;
    return response;
  }

  @override
  Future<Map<String, dynamic>> post(String path,
      {Object? data, String? operation, bool allowEmptyBody = false}) async {
    this.path = path;
    posts++;
    return response;
  }

  @override
  Future<List<int>> downloadBytes(
      {required String path,
      Map<String, dynamic>? queryParameters,
      String? operation}) async {
    this.path = path;
    query = queryParameters;
    return [1, 2];
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('dashboard contract preserves unavailable unit and activity', () async {
    final http = _Api()
      ..response = {
        'mine': 2,
        'unit': null,
        'sent': 4,
        'concluded': 1,
        'total': 6,
        'can_view_unit': false,
        'activity': [
          {
            'id': 'm',
            'correspondence_id': 'c',
            'type': 'DERIVED',
            'route_number': 'HR',
            'subject': 'QA',
            'created_at': '2026-10-14T12:00:00Z'
          }
        ]
      };
    final data = await DashboardApi(mainApi: http).getDashboard();
    expect(data.unit, isNull);
    expect(data.canViewUnit, isFalse);
    expect(data.activity.single.correspondenceId, 'c');
    expect(http.path, Endpoints.dashboard);
  });
  test(
      'notification read endpoints use authenticated actor without user selector',
      () async {
    final http = _Api()..response = {'unread': 0};
    final api = NotificationsApi(mainApi: http);
    await api.read('n1');
    expect(http.path, '/notifications/n1/read');
    await api.readAll();
    expect(http.path, '/notifications/read-all');
    expect(http.posts, 2);
    await api.count();
    expect(http.path, '/notifications/unread-count');
    expect(http.query, isNull);
  });
  test('report list and CSV carry identical filters', () async {
    final http = _Api()
      ..response = {
        'items': [],
        'total': 0,
        'page': 2,
        'page_size': 20,
        'total_pages': 0,
        'summary': {
          'total': 0,
          'pending': 0,
          'concluded': 0,
          'by_type': [],
          'by_unit': []
        }
      };
    final api = ReportsApi(mainApi: http);
    final filters = {
      'kind': 'received',
      'date_from': '2026-10-01',
      'status': 'ACTIVE',
      'search': 'QA'
    };
    await api.list(filters, page: 2);
    expect(http.query, {...filters, 'page': 2, 'page_size': 20});
    await api.export(filters);
    expect(http.query, filters);
    expect(http.path, '/reports/export.csv');
  });
  test('notification DTO preserves persistent read timestamp', () {
    final n = InternalNotificationResponse.fromJson({
      'id': 'n',
      'correspondence_id': null,
      'type': 'ASSIGNED',
      'title': 'QA',
      'message': 'QA',
      'is_read': true,
      'created_at': '2026-10-14T12:00:00Z',
      'read_at': '2026-10-14T13:00:00Z'
    });
    expect(n.isRead, isTrue);
    expect(n.readAt!.hour, 13);
    expect(n.correspondenceId, isNull);
  });
}
