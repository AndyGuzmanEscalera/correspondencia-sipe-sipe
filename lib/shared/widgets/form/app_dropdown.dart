import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/validator_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_form_field_style.dart';
import 'package:flutter/material.dart';

/// Dropdown estilo Inventario (`DropdownCustomPro`) con diseño Correspondencia.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    required this.controller,
    required this.items,
    required this.label,
    super.key,
    this.title,
    this.hint = 'Seleccione una opción',
    this.validators,
    this.onChanged,
  });

  final ControllerFieldDropdown<T> controller;
  final List<FormOption<T>> items;
  final String label;
  final String? title;
  final String hint;
  final List<AbstractValid>? validators;
  final void Function(FormOption<T>)? onChanged;

  String? _validate(FormOption<T>? value) {
    if (validators == null || validators!.isEmpty) return null;
    final text = value?.text ?? '';
    return Validator.validation(text, validators!);
  }

  @override
  Widget build(BuildContext context) {
    final selected = controller.isExist() ? controller.value : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppFormFieldStyle.title),
            const SizedBox(height: 8),
          ],
          DropdownButtonFormField<FormOption<T>>(
            key: controller.fieldKey,
            focusNode: controller.focusNode,
            isExpanded: true,
            value: selected,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validate,
            hint: Text(
              hint,
              style: AppFormFieldStyle.fieldText.copyWith(
                color: AppFormFieldStyle.fieldText.color?.withOpacity(0.55),
                fontWeight: FontWeight.w400,
              ),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            style: AppFormFieldStyle.fieldText,
            decoration: AppFormFieldStyle.dropdownDecoration(label: label),
            items: items
                .map(
                  (item) => DropdownMenuItem<FormOption<T>>(
                    value: item,
                    child: Text(item.text),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              controller.setValue(value);
              onChanged?.call(value);
            },
          ),
        ],
      ),
    );
  }
}
