import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:flutter/material.dart';

class UpsertCorrespondenceInherited extends InheritedWidget {
  UpsertCorrespondenceInherited({
    required super.child,
    required this.typeOperation,
    super.key,
  });

  static const typeItems = [
    FormOption<CorrespondenceTypeCode>(
      id: 1,
      text: 'Externa (CE)',
      value: CorrespondenceTypeCode.ce,
    ),
    FormOption<CorrespondenceTypeCode>(
      id: 2,
      text: 'Interna (CI)',
      value: CorrespondenceTypeCode.ci,
    ),
  ];

  static const priorityItems = [
    FormOption<String>(id: 1, text: 'Alta', value: 'Alta'),
    FormOption<String>(id: 2, text: 'Media', value: 'Media'),
    FormOption<String>(id: 3, text: 'Baja', value: 'Baja'),
  ];

  static const noUserOption = FormOption<String>(
    id: 0,
    text: 'Sin usuario específico',
    value: '',
  );

  final TypeOperation typeOperation;
  final formKey = GlobalKey<FormState>();
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

  static UpsertCorrespondenceInherited of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<UpsertCorrespondenceInherited>();
    assert(result != null, 'No UpsertCorrespondenceInherited found in context');
    return result!;
  }

  CorrespondenceTypeCode get selectedType =>
      type.get() ?? CorrespondenceTypeCode.ce;

  bool get isExternal => selectedType == CorrespondenceTypeCode.ce;

  void clear() {
    subject.textEditingController.clear();
    reference.textEditingController.clear();
    senderName.textEditingController.clear();
    senderDocument.textEditingController.clear();
    senderContact.textEditingController.clear();
    originDescription.textEditingController.clear();
    initialInstruction.textEditingController.clear();
    type.setDefaultValue(typeItems.first);
    priority.setDefaultValue(priorityItems[1]);
    documentType.clear();
    toUnit.clear();
    toUser.clear();
  }

  void clearExternalFields() {
    senderName.textEditingController.clear();
    senderDocument.textEditingController.clear();
    senderContact.textEditingController.clear();
    originDescription.textEditingController.clear();
  }

  void clearDestinationUser() {
    toUser.clear();
  }

  ResultValidate valid({required bool isExternal}) {
    final fieldKeys = <GlobalKey<FormFieldState<Object?>>>[
      subject.fieldKey,
      documentType.fieldKey,
      type.fieldKey,
      priority.fieldKey,
      toUnit.fieldKey,
    ];

    if (isExternal) {
      fieldKeys.add(senderName.fieldKey);
    }

    return formKey.validateAndGetErrors(fieldKeys);
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
