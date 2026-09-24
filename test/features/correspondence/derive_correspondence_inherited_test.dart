import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/helpers/derive_correspondence_inherited.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeriveCorrespondenceInherited', () {
    test('clear reinicia controllers', () {
      final inherited = DeriveCorrespondenceInherited(
        child: const SizedBox.shrink(),
      );
      inherited.toUnit.setDefaultValue(
        const FormOption<String>(id: 1, text: 'Sistemas', value: 'unit-1'),
      );
      inherited.toUser.setDefaultValue(
        const FormOption<String>(id: 2, text: 'Usuario', value: 'user-1'),
      );
      inherited.instruction.setValue('Instrucción');
      inherited.observation.setValue('Observación');

      inherited.clear();

      expect(inherited.toUnit.isExist(), isFalse);
      expect(inherited.toUser.isExist(), isFalse);
      expect(inherited.instruction.getValue(), isEmpty);
      expect(inherited.observation.getValue(), isEmpty);
      inherited.dispose();
    });

    test('clearDestinationUser limpia solo usuario destino', () {
      final inherited = DeriveCorrespondenceInherited(
        child: const SizedBox.shrink(),
      );
      inherited.toUnit.setDefaultValue(
        const FormOption<String>(id: 1, text: 'Sistemas', value: 'unit-1'),
      );
      inherited.toUser.setDefaultValue(
        const FormOption<String>(id: 2, text: 'Usuario', value: 'user-1'),
      );

      inherited.clearDestinationUser();

      expect(inherited.toUnit.isExist(), isTrue);
      expect(inherited.toUser.isExist(), isFalse);
      inherited.dispose();
    });

    testWidgets('valid falla sin unidad destino', (tester) async {
      late DeriveCorrespondenceInherited inherited;

      await tester.pumpWidget(
        MaterialApp(
          home: DeriveCorrespondenceInherited(
            child: Builder(
              builder: (context) {
                inherited = DeriveCorrespondenceInherited.of(context);
                return Scaffold(
                  body: Form(
                    key: inherited.formKey,
                    child: TextFormField(
                      key: inherited.toUnit.fieldKey,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      inherited.clear();
      expect(inherited.valid().isPassed, isFalse);
      inherited.dispose();
    });

    test('instruction y observation son opcionales', () {
      final inherited = DeriveCorrespondenceInherited(
        child: const SizedBox.shrink(),
      );

      inherited.toUnit.setDefaultValue(
        const FormOption<String>(id: 1, text: 'Sistemas', value: 'unit-1'),
      );
      inherited.instruction.setValue('');
      inherited.observation.setValue('');

      expect(inherited.instruction.getValue(), isEmpty);
      expect(inherited.observation.getValue(), isEmpty);
      inherited.dispose();
    });
  });
}
