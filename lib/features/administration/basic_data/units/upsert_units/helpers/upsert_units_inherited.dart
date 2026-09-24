import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:flutter/material.dart';

class UpsertUnitsInherited extends InheritedWidget {
  UpsertUnitsInherited({
    required super.child,
    required this.typeOperation,
    super.key,
  });

  static const noParent = FormOption<String>(
    id: 0,
    text: 'Sin unidad superior',
    value: '',
  );

  final TypeOperation typeOperation;
  final formKey = GlobalKey<FormState>();
  final code = ControllerFieldPro();
  final name = ControllerFieldPro();
  final description = ControllerFieldPro();
  final parent = ControllerFieldDropdown<String>();

  static UpsertUnitsInherited of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<UpsertUnitsInherited>();
    assert(result != null, 'No UpsertUnitsInherited found in context');
    return result!;
  }

  void setData(OrganizationalUnitAdmin entity) {
    code.setValue(entity.code ?? '');
    name.setValue(entity.name);
    description.setValue(entity.description ?? '');
    if (entity.parentId != null) {
      parent.setDefaultValue(
        FormOption<String>(
          id: entity.parentId!.hashCode,
          text: entity.parentName ?? entity.parentId!,
          value: entity.parentId!,
        ),
      );
    } else {
      parent.setDefaultValue(noParent);
    }
  }

  ResultValidate valid() {
    return formKey.validateAndGetErrors([
      code.fieldKey,
      name.fieldKey,
      description.fieldKey,
      parent.fieldKey,
    ]);
  }

  void clear() {
    code.textEditingController.clear();
    name.textEditingController.clear();
    description.textEditingController.clear();
    parent.setDefaultValue(noParent);
  }

  void dispose() {
    code.dispose();
    name.dispose();
    description.dispose();
    parent.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}
