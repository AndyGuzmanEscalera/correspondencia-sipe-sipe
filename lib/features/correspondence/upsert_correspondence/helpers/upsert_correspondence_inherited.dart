import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/models/pending_attachment.dart';
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
  final description = ControllerFieldPro();
  final senderName = ControllerFieldPro();
  final senderDocument = ControllerFieldPro();
  final senderContact = ControllerFieldPro();
  final originDescription = ControllerFieldPro();
  final initialInstruction = ControllerFieldPro();
  final type = ControllerFieldDropdown<CorrespondenceTypeCode>();
  final priority = ControllerFieldDropdown<String>();
  final documentType = ControllerFieldDropdown<String>();
  final originEmployee = ControllerFieldDropdown<String>();
  final toUnit = ControllerFieldDropdown<String>();
  final toUser = ControllerFieldDropdown<String>();

  final List<PendingAttachment> pendingAttachments = [];

  static UpsertCorrespondenceInherited of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<UpsertCorrespondenceInherited>();
    assert(result != null, 'No UpsertCorrespondenceInherited found in context');
    return result!;
  }

  CorrespondenceTypeCode get selectedType =>
      type.get() ?? CorrespondenceTypeCode.ce;

  bool get isExternal => selectedType == CorrespondenceTypeCode.ce;

  DocumentFormProfile profileFor(List<DocumentType> documentTypes) {
    final selected = findDocumentTypeById(documentTypes, documentType.get());
    if (selected == null) return DocumentFormProfile.generic;
    return resolveDocumentFormProfile(selected.code);
  }

  void addPendingAttachment(PendingAttachment attachment) {
    pendingAttachments.add(attachment);
  }

  void removePendingAttachmentAt(int index) {
    if (index >= 0 && index < pendingAttachments.length) {
      pendingAttachments.removeAt(index);
    }
  }

  void clearPendingAttachments() {
    pendingAttachments.clear();
  }

  void clear() {
    subject.textEditingController.clear();
    reference.textEditingController.clear();
    description.textEditingController.clear();
    senderName.textEditingController.clear();
    senderDocument.textEditingController.clear();
    senderContact.textEditingController.clear();
    originDescription.textEditingController.clear();
    initialInstruction.textEditingController.clear();
    type.setDefaultValue(typeItems.first);
    priority.setDefaultValue(priorityItems[1]);
    documentType.clear();
    originEmployee.clear();
    toUnit.clear();
    toUser.clear();
    clearPendingAttachments();
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

  ResultValidate valid({
    required DocumentFormProfile profile,
    required bool isExternal,
  }) {
    final fieldKeys = <GlobalKey<FormFieldState<Object?>>>[
      documentType.fieldKey,
      priority.fieldKey,
      toUnit.fieldKey,
    ];

    switch (profile) {
      case DocumentFormProfile.chaining:
        fieldKeys.addAll([type.fieldKey]);
        if (isExternal) {
          fieldKeys.add(senderName.fieldKey);
        } else {
          fieldKeys.add(originEmployee.fieldKey);
        }
      case DocumentFormProfile.technicalReport:
      case DocumentFormProfile.internalNote:
        fieldKeys.add(description.fieldKey);
        fieldKeys.add(originEmployee.fieldKey);
      case DocumentFormProfile.generic:
        fieldKeys.addAll([subject.fieldKey, type.fieldKey]);
        if (isExternal) {
          fieldKeys.add(senderName.fieldKey);
        }
    }

    final result = formKey.validateAndGetErrors(fieldKeys);

    if (result.isPassed &&
        profile == DocumentFormProfile.chaining &&
        subject.getValue().trim().isEmpty &&
        reference.getValue().trim().isEmpty) {
      return const ResultValidate(
        isPassed: false,
        errors: {'chaining': 'El asunto o la referencia es obligatorio'},
      );
    }

    return result;
  }

  void dispose() {
    subject.dispose();
    reference.dispose();
    description.dispose();
    senderName.dispose();
    senderDocument.dispose();
    senderContact.dispose();
    originDescription.dispose();
    initialInstruction.dispose();
    type.dispose();
    priority.dispose();
    documentType.dispose();
    originEmployee.dispose();
    toUnit.dispose();
    toUser.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
