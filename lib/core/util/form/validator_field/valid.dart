import 'validator_field.dart';

abstract class AbstractValid {
  String? valid(String? value);
}

class PasswordValid extends AbstractValid {
  PasswordValid({this.optional = false});
  final bool optional;
  static const minLength = 8;
  static const maxLength = 255;

  @override
  String? valid(String? value) {
    final text = value ?? '';
    if (text.isEmpty && optional) return null;
    if (text.trim().isEmpty) return 'Ingrese una contraseña.';
    if (text.runes.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres.';
    }
    if (text.runes.length > maxLength) {
      return 'La contraseña debe tener como máximo $maxLength caracteres.';
    }
    return null;
  }
}

class RequiredValid extends AbstractValid {
  RequiredValid({this.error});

  final String? error;

  @override
  String? valid(String? value) {
    if (!InputValidators.isRequired(value)) {
      return error ?? 'Campo requerido';
    }
    return null;
  }
}

class NumericValid extends AbstractValid {
  NumericValid({this.error});

  final String? error;

  @override
  String? valid(String? value) {
    if (!InputValidators.isNumeric(value)) {
      return error ?? 'Ingrese un valor numérico válido';
    }
    return null;
  }
}

/// Requiere que este campo u [otherValue] tenga contenido (regla "al menos uno").
class AtLeastOneOfValid extends AbstractValid {
  AtLeastOneOfValid({
    required this.otherValue,
    required this.error,
  });

  final String Function() otherValue;
  final String error;

  @override
  String? valid(String? value) {
    if (InputValidators.isRequired(value)) return null;
    if (InputValidators.isRequired(otherValue())) return null;
    return error;
  }
}
