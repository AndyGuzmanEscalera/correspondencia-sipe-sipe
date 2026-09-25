import 'dart:math' as math;

import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

/// Contenedor unificado y responsivo para diálogos de formulario CRUD.
///
/// Proporciona:
/// - Header fijo con título, subtítulo opcional y botón de cierre accesible.
/// - Contenido scrolleable protegido con [Scrollbar] y límite de altura.
/// - Footer fijo con botones de acción ([cancelLabel] y [submitLabel]).
/// - Comportamiento responsivo adaptable para mobile (390-430px), tablet y desktop.
class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    required this.title,
    required this.child,
    this.subtitle,
    this.onSubmit,
    this.onCancel,
    this.onClose,
    this.submitLabel = 'Guardar',
    this.cancelLabel = 'Cancelar',
    this.isLoading = false,
    this.isSubmitDisabled = false,
    this.maxWidth = 520.0,
    this.contentPadding,
    this.customActions,
    super.key,
  });

  /// Título del diálogo (ej: "Nueva unidad", "Editar funcionario").
  final String title;

  /// Subtítulo descriptivo opcional.
  final String? subtitle;

  /// Contenido principal del formulario (campos de entrada).
  final Widget child;

  /// Callback al presionar el botón de submit (Guardar/Registrar).
  final VoidCallback? onSubmit;

  /// Callback al presionar Cancelar (por defecto cierra el diálogo).
  final VoidCallback? onCancel;

  /// Callback al presionar el botón X (por defecto cierra el diálogo).
  final VoidCallback? onClose;

  /// Etiqueta del botón de acción primaria (ej. "Guardar", "Registrar").
  final String submitLabel;

  /// Etiqueta del botón de cancelación.
  final String cancelLabel;

  /// Indica si la operación está en curso para deshabilitar botones y mostrar loader.
  final bool isLoading;

  /// Permite deshabilitar el botón de submit independientemente de [isLoading].
  final bool isSubmitDisabled;

  /// Ancho máximo del diálogo en desktop (por defecto 520px).
  final double maxWidth;

  /// Padding opcional del contenido scrolleable.
  final EdgeInsetsGeometry? contentPadding;

  /// Acciones personalizadas para el footer en casos especiales.
  final Widget? customActions;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.width < 500;
    final maxDialogHeight = math.max(300.0, screenSize.height * 0.90);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxDialogHeight,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: UiColors.surface,
              borderRadius: AppDecorations.borderRadiusLg,
              border: Border.all(color: UiColors.borderLight),
              boxShadow: AppDecorations.shadowLg,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  title: title,
                  subtitle: subtitle,
                  onClose: onClose ?? () => Navigator.of(context).pop(),
                  isMobile: isMobile,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: UiColors.borderLight,
                ),
                Flexible(
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      padding: contentPadding ??
                          const EdgeInsets.fromLTRB(24, 20, 24, 10),
                      child: child,
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: UiColors.borderLight,
                ),
                _Footer(
                  customActions: customActions,
                  onCancel: onCancel ?? () => Navigator.of(context).pop(),
                  onSubmit: onSubmit,
                  cancelLabel: cancelLabel,
                  submitLabel: submitLabel,
                  isLoading: isLoading,
                  isSubmitDisabled: isSubmitDisabled,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onClose,
    required this.isMobile,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 24,
        18,
        isMobile ? 12 : 16,
        16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: UiColors.textPrimary,
                        letterSpacing: -0.2,
                        fontSize: isMobile ? 17 : 19,
                      ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: UiColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: UiColors.textSecondary,
            ),
            tooltip: 'Cerrar',
            onPressed: onClose,
            splashRadius: 20,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onCancel,
    required this.onSubmit,
    required this.cancelLabel,
    required this.submitLabel,
    required this.isLoading,
    required this.isSubmitDisabled,
    required this.isMobile,
    this.customActions,
  });

  final Widget? customActions;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;
  final String cancelLabel;
  final String submitLabel;
  final bool isLoading;
  final bool isSubmitDisabled;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (customActions != null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          14,
          isMobile ? 16 : 24,
          14,
        ),
        child: customActions!,
      );
    }

    final hasSubmit = onSubmit != null;

    final cancelButton = OutlinedButton(
      onPressed: isLoading ? null : onCancel,
      child: Text(hasSubmit ? cancelLabel : 'Cerrar'),
    );

    final submitButton = hasSubmit
        ? ElevatedButton(
            onPressed: (isLoading || isSubmitDisabled) ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(submitLabel),
          )
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        14,
        isMobile ? 16 : 24,
        14,
      ),
      child: isMobile
          ? Row(
              children: [
                Expanded(child: cancelButton),
                if (submitButton != null) ...[
                  const SizedBox(width: 12),
                  Expanded(child: submitButton),
                ],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                cancelButton,
                if (submitButton != null) ...[
                  const SizedBox(width: 12),
                  submitButton,
                ],
              ],
            ),
    );
  }
}
