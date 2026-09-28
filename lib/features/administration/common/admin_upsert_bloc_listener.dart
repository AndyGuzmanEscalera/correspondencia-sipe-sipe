import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_context.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cierra el [AppFormDialog] y muestra feedback en la lista, sin depender de
/// pulsar "Cerrar" en el diálogo de éxito (patrón Nueva Correspondencia).
class AdminUpsertBlocListener<B extends BlocBase<S>, S extends StatusState>
    extends StatefulWidget {
  const AdminUpsertBlocListener({
    required this.child,
    this.hostDialogContext,
    this.ownerContext,
    super.key,
  });

  final Widget child;

  /// Context del [showDialog] que envuelve el formulario.
  final BuildContext? hostDialogContext;

  /// Pantalla/lista que abrió el modal (feedback de éxito).
  final BuildContext? ownerContext;

  @override
  State<AdminUpsertBlocListener<B, S>> createState() =>
      _AdminUpsertBlocListenerState<B, S>();
}

class _AdminUpsertBlocListenerState<B extends BlocBase<S>, S extends StatusState>
    extends State<AdminUpsertBlocListener<B, S>> {
  bool _loadingOverlayOpen = false;

  void _closeFormDialog() {
    final host = widget.hostDialogContext;
    if (host != null && host.mounted) {
      Navigator.of(host).pop();
    }
  }

  void _dismissLoadingOverlay(BuildContext listenerContext) {
    if (!_loadingOverlayOpen) return;
    listenerContext.popDialog();
    _loadingOverlayOpen = false;
  }

  BuildContext _feedbackContext(BuildContext listenerContext) {
    final owner = widget.ownerContext;
    if (owner != null && owner.mounted) {
      return owner;
    }
    return listenerContext;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listenWhen: (previous, current) =>
          previous.generalStatus != current.generalStatus,
      listener: (listenerContext, state) {
        final message = state.dialogMessage;
        switch (state.generalStatus) {
          case GeneralStatus.loading:
            if (message.showLoading) {
              listenerContext.showAppLoading(message: message.message);
              _loadingOverlayOpen = true;
            }
          case GeneralStatus.error:
            _dismissLoadingOverlay(listenerContext);
            if (message.showError) {
              listenerContext.showAppError(
                message: message.message,
                title: message.title ?? 'Error',
              );
            }
          case GeneralStatus.success:
            _dismissLoadingOverlay(listenerContext);
            _closeFormDialog();
            final feedback = _feedbackContext(listenerContext);
            if (message.showSuccess) {
              feedback.showAppSuccess(
                message: message.message,
                title: message.title ?? 'Éxito',
              );
            }
          case GeneralStatus.initial:
            break;
        }
      },
      child: widget.child,
    );
  }
}
