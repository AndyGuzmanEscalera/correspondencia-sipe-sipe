import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contraseña requerida, mínima y máxima explican el requisito', () {
    final validator = PasswordValid();
    expect(validator.valid(''), 'Ingrese una contraseña.');
    expect(validator.valid('1234567'),
        'La contraseña debe tener al menos 8 caracteres.');
    expect(validator.valid('12345678'), isNull);
    expect(validator.valid('a' * 256),
        'La contraseña debe tener como máximo 255 caracteres.');
    expect(PasswordValid(optional: true).valid(''), isNull);
    expect(
        PasswordValid(optional: true).valid('123'), contains('8 caracteres'));
  });
}
