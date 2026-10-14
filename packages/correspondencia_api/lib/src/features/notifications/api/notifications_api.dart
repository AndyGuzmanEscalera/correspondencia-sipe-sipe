import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/responses.dart';

class NotificationsApi {
  NotificationsApi({required ApiMethod mainApi}) : _api = mainApi;
  final ApiMethod _api;
  Future<NotificationsPageResponse> list(
          {int page = 1, int pageSize = 20}) async =>
      NotificationsPageResponse.fromJson(await _api.get(Endpoints.notifications,
          queryParameters: {'page': page, 'page_size': pageSize},
          operation: 'notifications.list'));
  Future<int> count() async => (await _api.get(Endpoints.notificationCount,
      operation: 'notifications.count'))['unread'] as int;
  Future<int> read(String id) async =>
      (await _api.post(Endpoints.notificationRead(id),
          operation: 'notifications.read'))['unread'] as int;
  Future<int> readAll() async =>
      (await _api.post(Endpoints.notificationsReadAll,
          operation: 'notifications.readAll'))['unread'] as int;
}
