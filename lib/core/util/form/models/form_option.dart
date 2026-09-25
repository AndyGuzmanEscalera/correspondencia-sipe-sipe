/// Opción de dropdown — equivalente a `ValueExtend<T>` en Inventario.
class FormOption<T> {
  const FormOption({
    this.id = 0,
    this.text = '',
    this.value,
    this.description,
  });

  final int id;
  final String text;
  final T? value;
  final String? description;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FormOption<T> && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
