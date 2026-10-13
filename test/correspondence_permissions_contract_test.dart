import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/src/features/correspondence/mappers/correspondence_mapper.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/mappers/correspondence_entity_mapper.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final capability in [null, false, true]) {
    test(
        'La capacidad del servidor atraviesa API, Repository y detalle: $capability',
        () {
      final response = CorrespondenceResponse.fromJson({
        'id': 'document',
        'route_number': 'HR-QA',
        'route_year': 2026,
        'route_sequence': 1,
        'correspondence_type': 'INTERNAL',
        'document_type_code': 'NOTA',
        'document_type_name': 'Nota',
        'subject': 'QA',
        'priority': 'LOW',
        'status': 'ACTIVE',
        'registered_at': '2026-10-13T12:00:00Z',
        'current_unit_id': 'same-unit',
        'current_user_id': 'other-owner',
        if (capability != null) 'can_operate': capability,
      });
      final entity = response.toEntity().toUiEntity();
      final state = CorrespondenceDetailState(
          correspondence: entity, viewerUnitId: 'same-unit');
      expect(state.canOperateCurrentUnit, capability ?? false);
    });
  }
}
