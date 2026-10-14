import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';
import 'entities.dart';
import 'mappers.dart';

class NotificationsRepository {
  NotificationsRepository({required NotificationsApi api}) : _api = api;
  final NotificationsApi _api;
  Future<Result<NotificationsPage, Failure>> list({int page = 1}) =>
      handleExceptions(() async => (await _api.list(page: page)).toEntity(),
          feature: 'notifications', operation: 'list');
  Future<Result<int, Failure>> count() => handleExceptions(_api.count,
      feature: 'notifications', operation: 'count');
  Future<Result<int, Failure>> read(String id) =>
      handleExceptions(() => _api.read(id),
          feature: 'notifications', operation: 'read');
  Future<Result<int, Failure>> readAll() => handleExceptions(_api.readAll,
      feature: 'notifications', operation: 'readAll');
}
