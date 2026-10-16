import 'dart:async';

import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/notifications/cubit/notifications_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/notifications/views/notifications_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One monitor around the router: remains active on details and modal routes.
class NotificationsMonitor extends StatefulWidget {
  const NotificationsMonitor({
    required this.cubit,
    required this.session,
    required this.messengerKey,
    required this.navigatorKey,
    required this.child,
    super.key,
  });
  static const pollInterval = Duration(seconds: 60);
  final NotificationsCubit cubit;
  final AppSessionCubit session;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<NotificationsMonitor> createState() => _NotificationsMonitorState();
}

class _NotificationsMonitorState extends State<NotificationsMonitor>
    with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<AppSessionState>? _sessionSubscription;
  StreamSubscription<NotificationsState>? _notificationSubscription;
  String? _userId;
  int _lastAlert = 0;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _sessionSubscription = widget.session.stream.listen((_) => _syncSession());
    _notificationSubscription = widget.cubit.stream.listen(_showIncoming);
    _syncSession();
  }

  void _syncSession() {
    final id = widget.session.state.userSession?.id;
    if (id != _userId) {
      _stop();
      if (_userId != null) {
        widget.cubit.reset();
        widget.messengerKey.currentState?.clearSnackBars();
      }
      _lastAlert = 0;
      _userId = id;
    }
    if (id != null && _active) _start();
  }

  void _start() {
    if (_timer != null) return;
    unawaited(widget.cubit.poll());
    _timer = Timer.periodic(NotificationsMonitor.pollInterval,
        (_) => unawaited(widget.cubit.poll()));
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    widget.cubit.cancelPoll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _syncSession();
    } else {
      _stop();
    }
  }

  void _showIncoming(NotificationsState state) {
    final changed = state.alertVersion != _lastAlert;
    _lastAlert = state.alertVersion;
    if (!mounted ||
        !changed ||
        state.incoming.isEmpty ||
        !_active ||
        _userId == null ||
        _userId != widget.session.state.userSession?.id) return;
    final newest = state.incoming.first;
    final messenger = widget.messengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      showCloseIcon: true,
      content: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                state.incoming.length == 1
                    ? newest.title
                    : 'Tienes nuevas notificaciones',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(newest.message, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      action: SnackBarAction(label: 'Ver', onPressed: _openPanel),
    ));
  }

  void _openPanel() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null || !widget.session.state.isAuthenticated) return;
    unawaited(showDialog<void>(
      context: navigator.context,
      builder: (_) => BlocProvider.value(
        value: widget.cubit,
        child: NotificationsPanel(ownerContext: navigator.context),
      ),
    ));
  }

  @override
  void dispose() {
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sessionSubscription?.cancel());
    unawaited(_notificationSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
