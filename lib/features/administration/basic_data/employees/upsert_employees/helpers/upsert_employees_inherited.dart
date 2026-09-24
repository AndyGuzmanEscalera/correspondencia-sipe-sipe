import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:flutter/material.dart';

class UpsertEmployeesInherited extends InheritedWidget {
  UpsertEmployeesInherited({
    required super.child,
    required this.typeOperation,
    super.key,
  });

  final TypeOperation typeOperation;
  final formKey = GlobalKey<FormState>();
  final firstName = ControllerFieldPro();
  final lastName = ControllerFieldPro();
  final document = ControllerFieldPro();
  final email = ControllerFieldPro();
  final phone = ControllerFieldPro();
  final unit = ControllerFieldDropdown<String>();
  final position = ControllerFieldDropdown<String>();

  static UpsertEmployeesInherited of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<UpsertEmployeesInherited>();
    assert(result != null, 'No UpsertEmployeesInherited found in context');
    return result!;
  }

  void setData(EmployeeAdmin entity) {
    firstName.setValue(entity.firstName);
    lastName.setValue(entity.lastName);
    document.setValue(entity.documentNumber ?? '');
    email.setValue(entity.email ?? '');
    phone.setValue(entity.phone ?? '');
    if (entity.unitId != null) {
      unit.setDefaultValue(
        FormOption<String>(
          id: entity.unitId!.hashCode,
          text: entity.unitName ?? entity.unitId!,
          value: entity.unitId!,
        ),
      );
    }
    if (entity.positionId != null) {
      position.setDefaultValue(
        FormOption<String>(
          id: entity.positionId!.hashCode,
          text: entity.positionName ?? entity.positionId!,
          value: entity.positionId!,
        ),
      );
    }
  }

  ResultValidate valid() {
    return formKey.validateAndGetErrors([
      firstName.fieldKey,
      lastName.fieldKey,
      document.fieldKey,
      email.fieldKey,
      phone.fieldKey,
      unit.fieldKey,
      position.fieldKey,
    ]);
  }

  void clear() {
    firstName.textEditingController.clear();
    lastName.textEditingController.clear();
    document.textEditingController.clear();
    email.textEditingController.clear();
    phone.textEditingController.clear();
    unit.clear();
    position.clear();
  }

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    document.dispose();
    email.dispose();
    phone.dispose();
    unit.dispose();
    position.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}
