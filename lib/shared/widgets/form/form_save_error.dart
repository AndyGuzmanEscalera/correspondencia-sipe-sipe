import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

class FormSaveError extends StatelessWidget {
  const FormSaveError({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        message!,
        style: const TextStyle(
          color: UiColors.danger,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
