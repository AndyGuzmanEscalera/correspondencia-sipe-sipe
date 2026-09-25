import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

extension DialogContext on BuildContext {
  void showAppLoading({String message = 'Cargando...'}) {
    showDialog<void>(
      context: this,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDecorations.borderRadiusLg,
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(UiColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: UiColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showAppMessage({
    required String title,
    required String message,
    required Color color,
    VoidCallback? onClose,
  }) {
    showDialog<void>(
      context: this,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.info_outline, color: color, size: 36),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onClose?.call();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void showAppError({
    required String message,
    String title = 'Error',
    VoidCallback? onClose,
  }) {
    showAppMessage(
      title: title,
      message: message,
      color: Colors.red,
      onClose: onClose,
    );
  }

  void showAppSuccess({
    required String message,
    String title = 'Éxito',
    VoidCallback? onClose,
  }) {
    showAppMessage(
      title: title,
      message: message,
      color: Colors.green,
      onClose: onClose,
    );
  }

  void popDialog() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }
}
