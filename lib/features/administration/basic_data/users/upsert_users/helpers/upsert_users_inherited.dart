import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:flutter/material.dart';

class UpsertUsersInherited extends InheritedWidget {
  UpsertUsersInherited({
    required super.child,
    required this.typeOperation,
    super.key,
  });

  final TypeOperation typeOperation;
  final formKey = GlobalKey<FormState>();
  final username = ControllerFieldPro();
  final email = ControllerFieldPro();
  final password = ControllerFieldPro();
  final employee = ControllerFieldDropdown<String>();
  final rolePicker = ControllerFieldDropdown<String>();
  final Set<String> selectedRoleIds = {};

  static UpsertUsersInherited of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<UpsertUsersInherited>();
    assert(result != null, 'No UpsertUsersInherited found in context');
    return result!;
  }

  void setData(UserAdmin entity) {
    username.setValue(entity.username);
    email.setValue(entity.email ?? '');
    if (entity.employeeId != null) {
      employee.setDefaultValue(
        FormOption<String>(
          id: entity.employeeId!.hashCode,
          text: entity.employeeName ?? entity.employeeId!,
          value: entity.employeeId!,
        ),
      );
    }
  }

  void setRolesFromCatalog(UserAdmin entity, List<RoleOption> roles) {
    selectedRoleIds.clear();
    for (final code in entity.roleCodes) {
      final role = roles.firstWhere(
        (item) => item.code == code,
        orElse: () => const RoleOption(id: '', code: '', name: ''),
      );
      if (role.id.isNotEmpty) {
        selectedRoleIds.add(role.id);
      }
    }
  }

  void addRole(String roleId) {
    selectedRoleIds.add(roleId);
    rolePicker.clear();
  }

  void removeRole(String roleId) {
    selectedRoleIds.remove(roleId);
  }

  ResultValidate valid({required bool isCreate}) {
    final fieldKeys = <GlobalKey<FormFieldState<Object?>>>[
      username.fieldKey,
      email.fieldKey,
      employee.fieldKey,
    ];
    if (isCreate) {
      fieldKeys.add(password.fieldKey);
    }

    final result = formKey.validateAndGetErrors(fieldKeys);
    if (!result.isPassed) return result;

    if (selectedRoleIds.isEmpty) {
      return const ResultValidate(
        errors: {'roles': 'Seleccione al menos un rol'},
        isPassed: false,
      );
    }

    return result;
  }

  void clear() {
    username.textEditingController.clear();
    email.textEditingController.clear();
    password.textEditingController.clear();
    employee.clear();
    rolePicker.clear();
    selectedRoleIds.clear();
  }

  void dispose() {
    username.dispose();
    email.dispose();
    password.dispose();
    employee.dispose();
    rolePicker.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}
