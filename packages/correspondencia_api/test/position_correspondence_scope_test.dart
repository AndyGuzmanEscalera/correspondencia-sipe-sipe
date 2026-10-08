import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cargo serializa default false y actualización true', () {
    expect(
        const CreatePositionRequest(code: 'ANY', name: 'Director')
            .toJson()['can_view_unit_correspondence'],
        isFalse);
    expect(
        const UpdatePositionRequest(
                code: 'ANY', name: 'Cargo', canViewUnitCorrespondence: true)
            .toJson()['can_view_unit_correspondence'],
        isTrue);
    final json = <String, dynamic>{
      'id': 'p',
      'name': 'Cargo',
      'created_at': '2026-10-08T00:00:00Z',
      'updated_at': '2026-10-08T00:00:00Z'
    };
    expect(PositionAdminResponse.fromJson(json).canViewUnitCorrespondence,
        isFalse);
    expect(
        PositionAdminResponse.fromJson(
                {...json, 'can_view_unit_correspondence': true})
            .canViewUnitCorrespondence,
        isTrue);
  });
  test('counts transporta alcance actual y ausencia del campo falla cerrado',
      () {
    expect(
        CorrespondenceInboxCountsResponse.fromJson(
                {'mine': 1, 'unit': 3, 'can_view_unit_correspondence': true})
            .canViewUnitCorrespondence,
        isTrue);
    expect(
        CorrespondenceInboxCountsResponse.fromJson({'mine': 1, 'unit': 3})
            .canViewUnitCorrespondence,
        isFalse);
  });
}
