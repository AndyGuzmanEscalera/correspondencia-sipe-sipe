import 'package:flutter/material.dart';

extension DialogContext on BuildContext {
  void showAppLoading({String message = 'Cargando...'}) {
    showDialog<void>(
      context: this,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
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
