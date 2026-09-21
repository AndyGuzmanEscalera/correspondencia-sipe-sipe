import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:flutter/material.dart';

class ControllerFieldPro {
  ControllerFieldPro();

  final _textEditingController = TextEditingController();
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  final _focusNode = FocusNode();

  GlobalKey<FormFieldState<String>> get fieldKey => _fieldKey;
  FocusNode get focusNode => _focusNode;
  TextEditingController get textEditingController => _textEditingController;

  void setValue(String? value) {
    if (value == null) return;
    _textEditingController.text = value;
  }

  String getValue() => _textEditingController.text;

  void clear() => _textEditingController.clear();

  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
  }
}

class ControllerFieldDropdown<T> {
  FormOption<T> _value = FormOption<T>();
  FormOption<T>? _valueDefault;
  final _fieldKey = GlobalKey<FormFieldState<FormOption<T>>>();
  final _focusNode = FocusNode();

  GlobalKey<FormFieldState<FormOption<T>>> get fieldKey => _fieldKey;
  FocusNode get focusNode => _focusNode;
  FormOption<T> get value => _value;

  void setValue(FormOption<T>? value) {
    if (value == null) return;
    _value = value;
  }

  void setDefaultValue(FormOption<T> value) {
    _valueDefault = value;
    _value = value;
  }

  void clear() {
    _value = FormOption<T>();
  }

  bool isExist() => _value.id != 0;

  FormOption<T> getValue() => _value;

  T? get() => _value.value;

  FormOption<T>? getDefaultValue() => _valueDefault;

  void dispose() {
    _focusNode.dispose();
  }
}

extension FormKeyValidate on GlobalKey<FormState> {
  bool validateForm() => currentState?.validate() ?? false;
}
