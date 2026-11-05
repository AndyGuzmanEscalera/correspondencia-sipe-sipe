import 'package:correspondencia_api/correspondencia_api.dart' as api;
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_repository/src/features/correspondence/mappers/correspondence_mapper.dart';
import 'package:correspondencia_repository/src/features/correspondence/mappers/document_type_admin_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final behavior in DocumentBehavior.values) {
    test('mapper preserves behavior ${behavior.value}', () {
      final dto = api.DocumentTypeResponse(
          id: 't', code: 'CUSTOM', name: 'Nombre', behavior: behavior);
      expect(dto.toEntity().behavior, behavior);
      final admin = api.DocumentTypeAdminResponse(
          id: 'a',
          code: 'CUSTOM',
          name: 'Nombre',
          isActive: true,
          behavior: behavior,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026));
      expect(admin.toEntity().behavior, behavior);
    });
  }
  test('request mapper preserves route sheet issuance fields', () {
    const input = CreateCorrespondenceInput(
        correspondenceType: 'EXTERNAL',
        documentTypeId: 'r',
        priority: 'LOW',
        initialToUnitId: 'u',
        senderName: 'Ciudadano',
        emissionDate: '2026-10-20',
        emissionTime: '08:03',
        pageCount: 2);
    final json = input.toRequest().toJson();
    expect(json['emission_date'], input.emissionDate);
    expect(json['emission_time'], input.emissionTime);
    expect(json['page_count'], input.pageCount);
  });
  test('detail mapper preserves behavior and issuance', () {
    final dto = api.CorrespondenceResponse(
        id: 'r',
        routeNumber: 'HR-1',
        routeYear: 2026,
        routeSequence: 1,
        correspondenceType: 'EXTERNAL',
        documentTypeCode: 'CUSTOM',
        documentTypeName: 'Visible',
        documentBehavior: DocumentBehavior.routeSheet,
        subject: 'Asunto',
        priority: 'LOW',
        status: 'ACTIVE',
        registeredAt: DateTime(2026),
        emissionDate: '2026-10-20',
        emissionTime: '08:03',
        pageCount: 2,
        paraLabel: 'Autoridad');
    final row = dto.toEntity();
    expect(row.documentBehavior, DocumentBehavior.routeSheet);
    expect(row.pageCount, 2);
    expect(row.emissionDate, '2026-10-20');
    expect(row.paraLabel, 'Autoridad');
  });
}
