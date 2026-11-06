import 'package:correspondencia_api/correspondencia_api.dart';

class PublicRouteSheetMovement {
  const PublicRouteSheetMovement(this.date, this.label, this.unit);
  final DateTime date;
  final String label;
  final String? unit;
}

class PublicRouteSheetTracking {
  const PublicRouteSheetTracking(
      {required this.found,
      this.routeSheetNumber,
      this.statusLabel,
      this.reference,
      this.receivedAt,
      this.currentUnit,
      this.lastUpdatedAt,
      this.movements = const []});
  final bool found;
  final String? routeSheetNumber, statusLabel, reference, currentUnit;
  final DateTime? receivedAt, lastUpdatedAt;
  final List<PublicRouteSheetMovement> movements;
}

extension PublicTrackingMapper on PublicTrackingResponse {
  PublicRouteSheetTracking toEntity() => PublicRouteSheetTracking(
      found: found,
      routeSheetNumber: routeSheetNumber,
      statusLabel: statusLabel,
      reference: reference,
      currentUnit: currentUnit,
      receivedAt: DateTime.tryParse(receivedAt ?? ''),
      lastUpdatedAt: DateTime.tryParse(lastUpdatedAt ?? ''),
      movements: movements
          .map((e) =>
              PublicRouteSheetMovement(DateTime.parse(e.date), e.label, e.unit))
          .toList());
}

class PublicTrackingRepository {
  PublicTrackingRepository({PublicTrackingApi? api})
      : _api = api ?? PublicTrackingApi();
  final PublicTrackingApi _api;
  Future<PublicRouteSheetTracking> trackRouteSheet(
          String routeSheetNumber) async =>
      (await _api.trackRouteSheet(PublicTrackingRequest(routeSheetNumber)))
          .toEntity();
}
