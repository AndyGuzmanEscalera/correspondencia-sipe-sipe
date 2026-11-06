import '../../core/network/api_client.dart';
import '../../core/network/api_method.dart';

class PublicTrackingRequest {
  const PublicTrackingRequest(this.routeSheetNumber);
  final String routeSheetNumber;
  Map<String, dynamic> toJson() => {
        'route_sheet_number': routeSheetNumber.trim().toUpperCase(),
      };
}

class PublicTrackingMovement {
  const PublicTrackingMovement(
      {required this.date,
      required this.status,
      required this.label,
      this.unit});
  factory PublicTrackingMovement.fromJson(Map<String, dynamic> json) =>
      PublicTrackingMovement(
          date: json['date'] as String,
          status: json['status'] as String,
          label: json['label'] as String,
          unit: json['unit'] as String?);
  final String date, status, label;
  final String? unit;
}

class PublicTrackingResponse {
  const PublicTrackingResponse(
      {required this.found,
      this.routeSheetNumber,
      this.statusLabel,
      this.reference,
      this.receivedAt,
      this.currentUnit,
      this.lastUpdatedAt,
      this.movements = const []});
  factory PublicTrackingResponse.fromJson(Map<String, dynamic> json) =>
      PublicTrackingResponse(
          found: json['found'] == true,
          routeSheetNumber: json['route_sheet_number'] as String?,
          statusLabel: json['status_label'] as String?,
          reference: json['reference'] as String?,
          receivedAt: json['received_at'] as String?,
          currentUnit: json['current_unit'] as String?,
          lastUpdatedAt: json['last_updated_at'] as String?,
          movements: (json['movements'] as List? ?? const [])
              .map((e) => PublicTrackingMovement.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList());
  final bool found;
  final String? routeSheetNumber,
      statusLabel,
      reference,
      receivedAt,
      currentUnit,
      lastUpdatedAt;
  final List<PublicTrackingMovement> movements;
}

class PublicTrackingApi {
  PublicTrackingApi({ApiMethod? api})
      : _api = api ?? ApiClient.apiMethodFor(ApiClient.buildRefresh());
  // Dedicated unauthenticated client: no JWT and no session refresh.
  final ApiMethod _api;
  Future<PublicTrackingResponse> trackRouteSheet(
          PublicTrackingRequest request) async =>
      PublicTrackingResponse.fromJson(await _api.post(
          '/public/correspondence/track',
          data: request.toJson(),
          operation: 'publicTracking.track'));
}
