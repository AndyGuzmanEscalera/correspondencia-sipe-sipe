import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:failures/failures.dart';
import 'entities.dart';
import 'mappers.dart';

class DashboardRepository {
  DashboardRepository({required DashboardApi api}) : _api = api;
  final DashboardApi _api;
  Future<Result<DashboardData, Failure>> load() =>
      handleExceptions(() async => (await _api.getDashboard()).toEntity(),
          feature: 'dashboard', operation: 'load');
}
