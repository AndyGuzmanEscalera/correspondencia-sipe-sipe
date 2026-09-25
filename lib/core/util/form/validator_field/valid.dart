import 'validator_field.dart';

abstract class AbstractValid {
  String? valid(String? value);
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
