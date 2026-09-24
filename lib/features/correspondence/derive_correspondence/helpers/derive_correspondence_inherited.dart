import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:flutter/material.dart';

class DeriveCorrespondenceInherited extends InheritedWidget {
  DeriveCorrespondenceInherited({
    required super.child,
    super.key,
  });

  static const noUserOption = FormOption<String>(
    id: 0,
    text: 'Sin usuario específico',
    value: '',
  );

  final formKey = GlobalKey<FormState>();
  final toUnit = ControllerFieldDropdown<String>();
  final toUser = ControllerFieldDropdown<String>();
  final instruction = ControllerFieldPro();
  final observation = ControllerFieldPro();

  static DeriveCorrespondenceInherited of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<DeriveCorrespondenceInherited>();
    assert(result != null, 'No DeriveCorrespondenceInherited found in context');
    return result!;
  }

  void clear() {
    toUnit.clear();
    toUser.clear();
    instruction.textEditingController.clear();
    observation.textEditingController.clear();
  }

  void clearDestinationUser() {
    toUser.clear();
  }

  ResultValidate valid() {
    return formKey.validateAndGetErrors([
      toUnit.fieldKey,
    ]);
  }

  void dispose() {
    toUnit.dispose();
    toUser.dispose();
    instruction.dispose();
    observation.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
