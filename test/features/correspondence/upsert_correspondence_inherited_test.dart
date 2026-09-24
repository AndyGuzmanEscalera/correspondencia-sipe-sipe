import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertCorrespondenceInherited', () {
    test('clear reinicia controllers y defaults', () {
      final inherited = UpsertCorrespondenceInherited(
        typeOperation: TypeOperation.create,
        child: const SizedBox.shrink(),
      );
      inherited.subject.setValue('Asunto');
      inherited.senderName.setValue('Remitente');
      inherited.toUser.setDefaultValue(
        const FormOption<String>(id: 1, text: 'User', value: 'user-1'),
      );

      inherited.clear();

      expect(inherited.subject.getValue(), isEmpty);
      expect(inherited.senderName.getValue(), isEmpty);
      expect(inherited.toUser.isExist(), isFalse);
      expect(inherited.selectedType, CorrespondenceTypeCode.ce);
      inherited.dispose();
    });

    test('clearExternalFields limpia solo campos externos', () {
      final inherited = UpsertCorrespondenceInherited(
        typeOperation: TypeOperation.create,
        child: const SizedBox.shrink(),
      );
      inherited.subject.setValue('Asunto');
      inherited.senderName.setValue('Remitente');
      inherited.senderDocument.setValue('123');

      inherited.clearExternalFields();

      expect(inherited.subject.getValue(), 'Asunto');
      expect(inherited.senderName.getValue(), isEmpty);
      expect(inherited.senderDocument.getValue(), isEmpty);
      inherited.dispose();
    });

    testWidgets('valid INTERNAL no exige senderName', (tester) async {
      late UpsertCorrespondenceInherited inherited;

      await tester.pumpWidget(
        MaterialApp(
          home: UpsertCorrespondenceInherited(
            typeOperation: TypeOperation.create,
            child: Builder(
              builder: (context) {
                inherited = UpsertCorrespondenceInherited.of(context);
                return Scaffold(
                  body: Form(
                    key: inherited.formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          key: inherited.subject.fieldKey,
                          controller: inherited.subject.textEditingController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        TextFormField(
                          key: inherited.documentType.fieldKey,
                          validator: (value) => null,
                        ),
                        TextFormField(
                          key: inherited.type.fieldKey,
                          validator: (value) => null,
                        ),
                        TextFormField(
                          key: inherited.priority.fieldKey,
                          validator: (value) => null,
                        ),
                        TextFormField(
                          key: inherited.toUnit.fieldKey,
                          validator: (value) => null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      inherited.clear();
      inherited.type.setDefaultValue(
        UpsertCorrespondenceInherited.typeItems[1],
      );
      inherited.subject.setValue('Memorándum');

      final result = inherited.valid(
        profile: DocumentFormProfile.generic,
        isExternal: false,
      );
      expect(result.isPassed, isTrue);
      inherited.dispose();
    });
  });
}
