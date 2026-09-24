import 'package:correspondencia_sipe_sipe/core/platform/safe_filename.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeDownloadFilename', () {
    test('usa basename y elimina separadores de ruta', () {
      expect(
        sanitizeDownloadFilename(r'C:\temp\informe.pdf'),
        'informe.pdf',
      );
      expect(
        sanitizeDownloadFilename('/var/data/anexo.docx'),
        'anexo.docx',
      );
    });

    test('reemplaza caracteres inseguros', () {
      expect(
        sanitizeDownloadFilename('archivo<script>.pdf'),
        'archivo_script_.pdf',
      );
    });

    test('fallback cuando queda vacío', () {
      expect(sanitizeDownloadFilename('   '), 'archivo');
      expect(sanitizeDownloadFilename('///'), 'archivo');
    });
  });
}
