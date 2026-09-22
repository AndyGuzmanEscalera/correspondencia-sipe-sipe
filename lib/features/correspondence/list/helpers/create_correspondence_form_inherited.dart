import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:flutter/material.dart';

class CreateCorrespondenceFormInherited extends InheritedWidget {
  CreateCorrespondenceFormInherited({
    required super.child,
    super.key,
  }) {
    type.setDefaultValue(
      const FormOption<CorrespondenceTypeCode>(
        id: 1,
        text: 'Externa (CE)',
        value: CorrespondenceTypeCode.ce,
      ),
    );
    priority.setDefaultValue(
      const FormOption<String>(id: 2, text: 'Media', value: 'Media'),
    );
  }

  final subject = ControllerFieldPro();
  final reference = ControllerFieldPro();
  final senderName = ControllerFieldPro();
  final senderDocument = ControllerFieldPro();
  final senderContact = ControllerFieldPro();
  final originDescription = ControllerFieldPro();
  final initialInstruction = ControllerFieldPro();
  final type = ControllerFieldDropdown<CorrespondenceTypeCode>();
  final priority = ControllerFieldDropdown<String>();
  final documentType = ControllerFieldDropdown<String>();
  final toUnit = ControllerFieldDropdown<String>();
  final toUser = ControllerFieldDropdown<String>();
  final formKey = GlobalKey<FormState>();

  static CreateCorrespondenceFormInherited of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<CreateCorrespondenceFormInherited>();
    assert(
      result != null,
      'No CreateCorrespondenceFormInherited found in context',
    );
    return result!;
  }

  void dispose() {
    subject.dispose();
    reference.dispose();
    senderName.dispose();
    senderDocument.dispose();
    senderContact.dispose();
    originDescription.dispose();
    initialInstruction.dispose();
    type.dispose();
    priority.dispose();
    documentType.dispose();
    toUnit.dispose();
    toUser.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
