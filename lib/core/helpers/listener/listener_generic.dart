import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_context.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

class ListenerPro<B extends BlocBase<S>, S extends StatusState> {
  SingleChildWidget listen({
    bool showSuccess = true,
    bool showError = true,
    bool showLoading = true,
    VoidCallback? onPressedError,
    VoidCallback? onPressedSuccess,
  }) =>
      _FeedbackListener<B, S>(
        showSuccess: showSuccess,
        showError: showError,
        showLoading: showLoading,
        onPressedError: onPressedError,
        onPressedSuccess: onPressedSuccess,
      );

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

class _FeedbackListener<B extends BlocBase<S>, S extends StatusState>
    extends SingleChildStatefulWidget {
  const _FeedbackListener(
      {required this.showSuccess,
      required this.showError,
      required this.showLoading,
      this.onPressedError,
      this.onPressedSuccess});
  final bool showSuccess, showError, showLoading;
  final VoidCallback? onPressedError, onPressedSuccess;
  @override
  SingleChildState<_FeedbackListener<B, S>> createState() =>
      _FeedbackListenerState<B, S>();
}

class _FeedbackListenerState<B extends BlocBase<S>, S extends StatusState>
    extends SingleChildState<_FeedbackListener<B, S>> {
  DialogRoute<void>? _loadingRoute;
  void _dismissLoading() {
    final route = _loadingRoute;
    _loadingRoute = null;
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) =>
      BlocListener<B, S>(
        listenWhen: (previous, current) =>
            previous.generalStatus != current.generalStatus,
        listener: (context, state) {
          final message = state.dialogMessage;
          if (state.generalStatus == GeneralStatus.loading) {
            if (message.showLoading &&
                widget.showLoading &&
                _loadingRoute == null) {
              _loadingRoute = context.showAppLoading(message: message.message);
            }
          } else if (state.generalStatus == GeneralStatus.error) {
            _dismissLoading();
            if (message.showError && widget.showError) {
              context.showAppError(
                  message: message.message,
                  title: message.title ?? 'Error',
                  onClose: widget.onPressedError);
            }
          } else if (state.generalStatus == GeneralStatus.success) {
            _dismissLoading();
            if (message.showSuccess && widget.showSuccess) {
              context.showAppSuccess(
                  message: message.message,
                  title: message.title ?? 'Éxito',
                  onClose: widget.onPressedSuccess);
            }
          }
        },
        child: child,
      );
}
