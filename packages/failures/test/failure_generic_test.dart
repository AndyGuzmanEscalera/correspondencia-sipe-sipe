import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FailureGeneric.message', () {
    test('ValidationFailure muestra el mensaje del servidor', () {
      expect(
        FailureGeneric.message(
          failure: const ValidationFailure('Detalle del backend'),
          messageResult: 'No se pudo registrar la correspondencia',
        ),
        'Detalle del backend',
      );
    });

    test('GenericFailure técnico usa messageResult', () {
      expect(
        FailureGeneric.message(
          failure: const GenericFailure('Error específico'),
          messageResult: 'Mensaje genérico',
        ),
        'Mensaje genérico',
      );
    });

    test('GenericFailure vacío usa messageResult', () {
      expect(
        FailureGeneric.message(
          failure: const GenericFailure(''),
          messageResult: 'Mensaje genérico',
        ),
        'Mensaje genérico',
      );
    });
  });

  group('handleExceptions RequestException', () {
    test('422 se convierte en ValidationFailure con el mismo texto', () async {
      final result = await handleExceptions<String>(() async {
        throw RequestException(
          'Su cuenta no está vinculada',
          statusCode: 422,
        );
      });

      final failure = result.failureOrNull();
      expect(failure, isA<ValidationFailure>());
      expect(
        FailureGeneric.message(
          failure: failure!,
          messageResult: 'No se pudo registrar la correspondencia',
        ),
        'Su cuenta no está vinculada',
      );
    });
  });
}
