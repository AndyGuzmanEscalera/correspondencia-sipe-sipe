import '../../../core/network/api_method.dart';
import '../../../core/network/endpoints.dart';
import '../models/responses.dart';

class DashboardApi {
  DashboardApi({required ApiMethod mainApi}) : _api = mainApi;
  final ApiMethod _api;
  Future<DashboardDataResponse> getDashboard() async =>
      DashboardDataResponse.fromJson(
          await _api.get(Endpoints.dashboard, operation: 'dashboard.load'));
}
