import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:flutter/material.dart';

class UpsertHierarchiesInherited extends InheritedWidget {
  UpsertHierarchiesInherited(
      {required super.child, required this.typeOperation, super.key});
  final TypeOperation typeOperation;
  final formKey = GlobalKey<FormState>();
  final code = ControllerFieldPro();
  final name = ControllerFieldPro();
  final rank = ControllerFieldPro();
  static UpsertHierarchiesInherited of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UpsertHierarchiesInherited>()!;
  void setData(PositionHierarchy row) {
    code.setValue(row.code);
    name.setValue(row.name);
    rank.setValue(row.rank.toString());
  }

  void clear() {
    code.setValue('');
    name.setValue('');
    rank.setValue('');
  }

  ResultValidate valid() => formKey
      .validateAndGetErrors([code.fieldKey, name.fieldKey, rank.fieldKey]);
  void dispose() {
    code.dispose();
    name.dispose();
    rank.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
