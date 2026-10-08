import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:flutter/material.dart';

class UpsertPositionsInherited extends InheritedWidget {
  UpsertPositionsInherited({
    required super.child,
    required this.typeOperation,
    super.key,
  });

  final TypeOperation typeOperation;
  final formKey = GlobalKey<FormState>();
  final code = ControllerFieldPro();
  final name = ControllerFieldPro();
  final description = ControllerFieldPro();
  final canViewUnitCorrespondence = ValueNotifier<bool>(false);

  static UpsertPositionsInherited of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<UpsertPositionsInherited>();
    assert(result != null, 'No UpsertPositionsInherited found in context');
    return result!;
  }

  void setData(PositionAdmin entity) {
    canViewUnitCorrespondence.value = entity.canViewUnitCorrespondence;
    code.setValue(entity.code ?? '');
    name.setValue(entity.name);
    description.setValue(entity.description ?? '');
  }

  ResultValidate valid() {
    return formKey.validateAndGetErrors([
      code.fieldKey,
      name.fieldKey,
      description.fieldKey,
    ]);
  }

  void clear() {
    canViewUnitCorrespondence.value = false;
    code.textEditingController.clear();
    name.textEditingController.clear();
    description.textEditingController.clear();
  }

  void dispose() {
    canViewUnitCorrespondence.dispose();
    code.dispose();
    name.dispose();
    description.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}
