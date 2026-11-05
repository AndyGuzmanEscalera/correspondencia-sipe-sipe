import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final behavior in DocumentBehavior.values) {
    test('wire round trip ${behavior.value}', () {
      expect(DocumentBehavior.fromJson(behavior.value), behavior);
      final dto = DocumentTypeResponse.fromJson({
        'id': 'id',
        'code': 'CUSTOM',
        'name': 'Cualquier nombre',
        'behavior': behavior.value,
      });
      expect(dto.behavior, behavior);
    });
  }
  test('invalid explicit behavior is rejected', () {
    expect(
        () => DocumentTypeResponse.fromJson({
              'id': 'id',
              'code': 'INFORME',
              'name': 'Informe',
              'behavior': 'INVALID'
            }),
        throwsFormatException);
  });
  test('explicit GENERIC wins over known code', () {
    expect(
        DocumentTypeResponse.fromJson({
          'id': 'id',
          'code': 'INFORME',
          'name': 'Informe',
          'behavior': 'GENERIC'
        }).behavior,
        DocumentBehavior.generic);
  });
  test('old server compatibility is limited to missing behavior', () {
    for (final entry in {
      'EDIE': DocumentBehavior.legacyChaining,
      'NOTA': DocumentBehavior.legacyInternalNote,
      'INFORME': DocumentBehavior.report,
      'CUSTOM': DocumentBehavior.generic,
    }.entries) {
      expect(
          DocumentTypeResponse.fromJson(
              {'id': 'id', 'code': entry.key, 'name': 'Nombre'}).behavior,
          entry.value);
    }
  });
  test('route issuance request preserves explicit date time and pages', () {
    final json = const CreateCorrespondenceRequest(
            correspondenceType: 'EXTERNAL',
            documentTypeId: 'route',
            priority: 'LOW',
            initialToUnitId: 'unit',
            senderName: 'Ciudadano',
            reference: 'Referencia',
            description: 'Contenido',
            emissionDate: '2026-10-20',
            emissionTime: '08:03',
            pageCount: 2)
        .toJson();
    expect(json['emission_date'], '2026-10-20');
    expect(json['emission_time'], '08:03');
    expect(json['page_count'], 2);
    expect(json.containsKey('origin_employee_id'), isFalse);
  });
  test('admin enum is serialized explicitly', () {
    expect(
        const CreateDocumentTypeRequest(
                code: 'X', name: 'X', behavior: DocumentBehavior.report)
            .toJson()['behavior'],
        'REPORT');
    expect(
        const UpdateDocumentTypeRequest(
                name: 'X', behavior: DocumentBehavior.generic)
            .toJson()['behavior'],
        'GENERIC');
  });
}
