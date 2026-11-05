import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:flutter/material.dart';

class UpsertDocumentTypesInherited extends InheritedWidget {
  UpsertDocumentTypesInherited({
    required super.child,
    required this.typeOperation,
    super.key,
  });

  final TypeOperation typeOperation;
  final formKey = GlobalKey<FormState>();
  final code = ControllerFieldPro();
  final _behavior = ValueNotifier(DocumentBehavior.generic);
  DocumentBehavior get behavior => _behavior.value;
  set behavior(DocumentBehavior value) => _behavior.value = value;
  final name = ControllerFieldPro();

  static UpsertDocumentTypesInherited of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<UpsertDocumentTypesInherited>();
    assert(
      result != null,
      'No UpsertDocumentTypesInherited found in context',
    );
    return result!;
  }

  void setData(DocumentTypeAdmin entity) {
    code.setValue(entity.code);
    behavior = entity.behavior;
    name.setValue(entity.name);
  }

  ResultValidate valid() {
    return formKey.validateAndGetErrors([
      code.fieldKey,
      name.fieldKey,
    ]);
  }

  void clear() {
    code.textEditingController.clear();
    behavior = DocumentBehavior.generic;
    name.textEditingController.clear();
  }

  void dispose() {
    code.dispose();
    _behavior.dispose();
    name.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}
