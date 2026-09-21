import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:flutter/material.dart';

class PublicConsultFormInherited extends InheritedWidget {
  PublicConsultFormInherited({
    required super.child,
    super.key,
  }) {
    final currentYear = DateTime.now().year;
    year.setDefaultValue(
      FormOption<int>(id: currentYear, text: '$currentYear', value: currentYear),
    );
  }

  final year = ControllerFieldDropdown<int>();
  final fullName = ControllerFieldPro();
  final documentId = ControllerFieldPro();
  final phone = ControllerFieldPro();
  final uniqueNumber = ControllerFieldPro();
  final formKey = GlobalKey<FormState>();

  static PublicConsultFormInherited of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<PublicConsultFormInherited>();
    assert(result != null, 'No PublicConsultFormInherited found in context');
    return result!;
  }

  void dispose() {
    year.dispose();
    fullName.dispose();
    documentId.dispose();
    phone.dispose();
    uniqueNumber.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
