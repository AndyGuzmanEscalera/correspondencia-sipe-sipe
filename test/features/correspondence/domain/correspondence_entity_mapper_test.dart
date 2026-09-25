import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/mappers/correspondence_entity_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CorrespondenceToEntity', () {
    test('preserva currentUnitId y currentUserId del repositorio', () {
      final repoItem = Correspondence(
        id: 'corr-1',
        routeNumber: 'HR-2026-000010',
        routeYear: 2026,
        routeSequence: 10,
        correspondenceType: 'INTERNAL',
        documentTypeCode: 'NOTA',
        documentTypeName: 'Nota Interna',
        subject: 'Asunto prueba',
        priority: 'HIGH',
        status: 'ACTIVE',
        currentUnitId: 'unit-juridica',
        currentUnitName: 'Dirección Jurídica',
        currentUserId: 'user-carlos',
        currentUserName: 'Carlos Pérez',
        currentUserIsActive: true,
        registeredAt: DateTime.utc(2026, 3, 1),
      );

      final entity = repoItem.toUiEntity();

      expect(entity.currentUnitId, 'unit-juridica');
      expect(entity.currentUserId, 'user-carlos');
      expect(entity.currentUnitName, 'Dirección Jurídica');
      expect(entity.currentUserName, 'Carlos Pérez');
      expect(entity.currentUserIsActive, isTrue);
    });

    test('separa tipo documental de origen INTERNAL/EXTERNAL', () {
      final internal = Correspondence(
        id: 'corr-int',
        routeNumber: 'HR-2026-000011',
        routeYear: 2026,
        routeSequence: 11,
        correspondenceType: 'INTERNAL',
        documentTypeCode: 'INFORME',
        documentTypeName: 'Informe Técnico',
        subject: 'Interno',
        priority: 'MEDIUM',
        status: 'ACTIVE',
        registeredAt: DateTime.utc(2026, 3, 2),
      ).toUiEntity();

      final external = Correspondence(
        id: 'corr-ext',
        routeNumber: 'HR-2026-000012',
        routeYear: 2026,
        routeSequence: 12,
        correspondenceType: 'EXTERNAL',
        documentTypeCode: 'EDIE',
        documentTypeName: 'Encadenamiento',
        subject: 'Externo',
        priority: 'LOW',
        status: 'ACTIVE',
        registeredAt: DateTime.utc(2026, 3, 3),
      ).toUiEntity();

      expect(internal.documentTypeLabel, 'Informe Técnico');
      expect(internal.originTypeLabel, 'Interna');
      expect(internal.type, CorrespondenceTypeCode.ci);

      expect(external.documentTypeLabel, 'Encadenamiento');
      expect(external.originTypeLabel, 'Externa');
      expect(external.type, CorrespondenceTypeCode.ce);
    });

    test('marca responsable inactivo sin perder unidad', () {
      final entity = Correspondence(
        id: 'corr-inactive',
        routeNumber: 'HR-2026-000013',
        routeYear: 2026,
        routeSequence: 13,
        correspondenceType: 'INTERNAL',
        documentTypeCode: 'NOTA',
        documentTypeName: 'Nota Interna',
        subject: 'Trámite',
        priority: 'MEDIUM',
        status: 'ACTIVE',
        currentUnitId: 'unit-juridica',
        currentUnitName: 'Dirección Jurídica',
        currentUserId: 'user-carlos',
        currentUserName: 'Carlos Pérez',
        currentUserIsActive: false,
        registeredAt: DateTime.utc(2026, 3, 4),
      ).toUiEntity();

      expect(entity.currentResponsibleUnitLabel, 'Dirección Jurídica');
      expect(entity.currentResponsibleUserLabel, 'Carlos Pérez · Inactivo');
    });
  });
}
