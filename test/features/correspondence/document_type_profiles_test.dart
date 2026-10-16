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

    test('codigo completo del catalogo reconoce encadenamiento y PDF', () {
      const code = 'ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS';
      expect(resolveDocumentFormProfile(code.toLowerCase()),
          DocumentFormProfile.chaining);
      expect(supportsEncadenamientoPdf('  $code  '), isTrue);
      expect(supportsEncadenamientoPdf('NOTA DE COMPRA'), isFalse);
      expect(
          resolveDefaultChainingDocumentType(const [
            DocumentType(
                id: 'otro', code: 'NOTA DE COMPRA', name: 'Nota de compra'),
            DocumentType(id: 'enc', code: code, name: code),
          ])?.id,
          'enc');
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
