import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list/helpers/create_correspondence_form_inherited.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('changing unit clears previously selected destination user', (
    tester,
  ) async {
    late CreateCorrespondenceFormInherited inherited;

    await tester.pumpWidget(
      MaterialApp(
        home: CreateCorrespondenceFormInherited(
          child: Builder(
            builder: (context) {
              inherited = CreateCorrespondenceFormInherited.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    inherited.toUser.setValue(
      const FormOption<String>(id: 1, text: 'Usuario', value: 'user-1'),
    );
    expect(inherited.toUser.isExist(), isTrue);

    inherited.toUser.clear();
    expect(inherited.toUser.isExist(), isFalse);
  });
}
