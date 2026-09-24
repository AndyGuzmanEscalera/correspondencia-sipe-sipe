import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('document_type_profiles', () {
    test('resolveDocumentFormProfile mapea por código', () {
      expect(resolveDocumentFormProfile('EDIE'), DocumentFormProfile.chaining);
      expect(resolveDocumentFormProfile('s'), DocumentFormProfile.chaining);
      expect(
        resolveDocumentFormProfile('INFORME'),
        DocumentFormProfile.technicalReport,
      );
      expect(
        resolveDocumentFormProfile('NOTA'),
        DocumentFormProfile.internalNote,
      );
      expect(
        resolveDocumentFormProfile('OTRO'),
        DocumentFormProfile.generic,
      );
    });

    test('resolveDefaultChainingDocumentType prioriza S luego EDIE', () {
      const types = [
        DocumentType(id: '1', code: 'NOTA', name: 'Nota'),
        DocumentType(id: '2', code: 'EDIE', name: 'Encadenamiento'),
      ];

      expect(resolveDefaultChainingDocumentType(types)?.code, 'EDIE');

      const withS = [
        DocumentType(id: '3', code: 'S', name: 'S'),
        DocumentType(id: '2', code: 'EDIE', name: 'Encadenamiento'),
      ];
      expect(resolveDefaultChainingDocumentType(withS)?.code, 'S');
    });
  });
}
