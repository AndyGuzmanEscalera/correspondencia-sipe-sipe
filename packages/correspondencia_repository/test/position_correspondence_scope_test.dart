import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/src/features/organization/mappers/organization_admin_mapper.dart';
import 'package:correspondencia_repository/src/features/correspondence/mappers/correspondence_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapper y entidades conservan alcance explícito por cargo', () {
    const input = PositionInput(
        code: 'ANY', name: 'Director', canViewUnitCorrespondence: true);
    expect(input.toCreateRequest().toJson()['can_view_unit_correspondence'],
        isTrue);
    expect(input.toUpdateRequest().toJson()['can_view_unit_correspondence'],
        isTrue);
    final item = PositionAdminResponse(
            id: 'p',
            name: 'Cargo',
            isActive: true,
            canViewUnitCorrespondence: true,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026))
        .toEntity();
    expect(item.canViewUnitCorrespondence, isTrue);
    expect(
        const PositionInput(code: 'ANY', name: 'Director')
            .canViewUnitCorrespondence,
        isFalse);
    expect(
        const CorrespondenceInboxCountsResponse(
                mine: 1, unit: 3, canViewUnitCorrespondence: true)
            .toEntity()
            .canViewUnitCorrespondence,
        isTrue);
  });
}
