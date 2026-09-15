import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_context.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListenerPro<B extends BlocBase<S>, S extends StatusState> {
  BlocListener<B, S> listen({
    bool showSuccess = true,
    bool showError = true,
    bool showLoading = true,
    VoidCallback? onPressedError,
    VoidCallback? onPressedSuccess,
  }) {
    return BlocListener<B, S>(
      listenWhen: (previous, current) =>
          previous.generalStatus != current.generalStatus,
      listener: (context, state) {
        final status = state.generalStatus;
        final message = state.dialogMessage;

        if (status == GeneralStatus.loading) {
          if (message.showLoading && showLoading) {
            context.showAppLoading(message: message.message);
          }
        } else if (status == GeneralStatus.error) {
          context.popDialog();
          if (message.showError && showError) {
            context.showAppError(
              message: message.message,
              title: message.title ?? 'Error',
              onClose: onPressedError,
            );
          }
        } else if (status == GeneralStatus.success) {
          context.popDialog();
          if (message.showSuccess && showSuccess) {
            context.showAppSuccess(
              message: message.message,
              title: message.title ?? 'Éxito',
              onClose: onPressedSuccess,
            );
          }
        }
      },
    );
  }

  BlocListener<B, S> event({
    void Function(S state)? onSuccess,
    void Function(S state)? onError,
    void Function(S state)? onLoading,
  }) {
    return BlocListener<B, S>(
      listenWhen: (previous, current) =>
          previous.generalStatus != current.generalStatus,
      listener: (context, state) {
        switch (state.generalStatus) {
          case GeneralStatus.loading:
            onLoading?.call(state);
          case GeneralStatus.success:
            onSuccess?.call(state);
          case GeneralStatus.error:
            onError?.call(state);
          case GeneralStatus.initial:
            break;
        }
      },
    );
  }
}
