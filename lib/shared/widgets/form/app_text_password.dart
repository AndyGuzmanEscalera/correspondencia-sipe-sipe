import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/validator_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_form_field_style.dart';
import 'package:flutter/material.dart';

/// Password estilo Inventario (`CustomTextPassword`) con diseño Correspondencia.
class AppTextPassword extends StatefulWidget {
  const AppTextPassword({
    required this.controller,
    required this.label,
    super.key,
    this.title,
    this.validators,
    this.onSubmitted,
    this.autofillHints,
  });

  final ControllerFieldPro controller;
  final String label;
  final String? title;
  final List<AbstractValid>? validators;
  final void Function(String)? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextPassword> createState() => _AppTextPasswordState();
}

class _AppTextPasswordState extends State<AppTextPassword> {
  bool _obscure = true;

  String? _validate(String? value) {
    return Validator.validation(value, widget.validators ?? <AbstractValid>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            Text(widget.title!, style: AppFormFieldStyle.title),
            const SizedBox(height: 8),
          ],
          TextFormField(
            key: widget.controller.fieldKey,
            controller: widget.controller.textEditingController,
            focusNode: widget.controller.focusNode,
            obscureText: _obscure,
            autofillHints: widget.autofillHints,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validate,
            onFieldSubmitted: widget.onSubmitted,
            style: AppFormFieldStyle.fieldText,
            decoration: AppFormFieldStyle.decoration(
              label: widget.label,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: UiColors.textMuted,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
