import 'valid.dart';

class InputValidators {
  static bool isRequired(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool isNumeric(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(r'^[0-9]+$').hasMatch(value.trim());
  }
}

class Validator {
  static String? validation(String? value, List<AbstractValid> validators,
      {String? fieldLabel}) {
    for (final element in validators) {
      final error = element.valid(value);
      if (error != null) {
        return error == 'Campo requerido' && fieldLabel != null
            ? '$fieldLabel: Este campo es obligatorio.'
            : error;
      }
    }
    return null;
  }
}
