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
