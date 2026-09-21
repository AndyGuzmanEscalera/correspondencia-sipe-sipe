import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:flutter/material.dart';

class SignInFormInherited extends InheritedWidget {
  SignInFormInherited({
    required super.child,
    super.key,
  });

  final username = ControllerFieldPro();
  final password = ControllerFieldPro();
  final formKey = GlobalKey<FormState>();

  static SignInFormInherited of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<SignInFormInherited>();
    assert(result != null, 'No SignInFormInherited found in context');
    return result!;
  }

  void dispose() {
    username.dispose();
    password.dispose();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
