import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePublicApi extends PublicTrackingApi {
  @override
  Future<PublicTrackingResponse> trackRouteSheet(
          PublicTrackingRequest request) async =>
      const PublicTrackingResponse(
          found: true,
          routeSheetNumber: 'HR-2026-000123',
          statusLabel: 'Recibido',
          receivedAt: '2026-11-06T12:00:00Z',
          movements: [
            PublicTrackingMovement(
                date: '2026-11-06T12:00:00Z',
                status: 'RECEIVED',
                label: 'Recibido')
          ]);
}

void main() {
  test('public mapper and repository retain only public information', () async {
    final result = await PublicTrackingRepository(api: FakePublicApi())
        .trackRouteSheet('HR-2026-000123');
    expect(result.found, isTrue);
    expect(result.receivedAt, DateTime.utc(2026, 11, 6, 12));
    expect(result.movements.single.label, 'Recibido');
  });
  test('not-found mapping has no fabricated result', () {
    final result = const PublicTrackingResponse(found: false).toEntity();
    expect(result.found, isFalse);
    expect(result.routeSheetNumber, isNull);
    expect(result.movements, isEmpty);
  });
}
