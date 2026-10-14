import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/institutional_date.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_page.dart';
import 'package:correspondencia_sipe_sipe/features/notifications/cubit/notifications_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});
  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<NotificationsCubit>())
      return const SizedBox.shrink();
    final cubit = getIt<NotificationsCubit>();
    return BlocBuilder<NotificationsCubit, NotificationsState>(
        bloc: cubit,
        builder: (context, state) => IconButton(
            tooltip: 'Notificaciones',
            icon: Badge(
                isLabelVisible: (state.unread ?? 0) > 0,
                label: Text('${state.unread ?? 0}'),
                child: const Icon(Icons.notifications_outlined)),
            onPressed: () async {
              await showDialog<void>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: NotificationsPanel(
                          ownerContext: context,
                          onReturn: () async {
                            if (context.mounted)
                              await context
                                  .read<SideMenuCubit>()
                                  .refreshBadges();
                          })));
              await cubit.refreshCount();
            }));
  }
}

class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel(
      {required this.ownerContext, this.openDetail, this.onReturn, super.key});
  final BuildContext ownerContext;
  final Future<void> Function()? onReturn;
  final Future<void> Function(BuildContext, String)? openDetail;
  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().refresh(page: 1);
  }

  @override
  Widget build(BuildContext context) => Dialog(
      child: SizedBox(
          width: 600,
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                  builder: (context, state) {
                final cubit = context.read<NotificationsCubit>();
                final items = state.data?.items ?? [];
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text('Notificaciones',
                                style: Theme.of(context).textTheme.titleLarge)),
                        IconButton(
                            tooltip: 'Actualizar notificaciones',
                            onPressed: () => cubit.refresh(),
                            icon: const Icon(Icons.refresh)),
                        IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close))
                      ]),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                              onPressed: state.busy ? null : cubit.markAll,
                              child: const Text('Marcar todas como leídas'))),
                      if (state.generalStatus == GeneralStatus.loading)
                        const LinearProgressIndicator(),
                      if (state.generalStatus == GeneralStatus.error)
                        Text(state.dialogMessage.message),
                      Expanded(
                          child: items.isEmpty
                              ? Center(
                                  child: Text(state.generalStatus ==
                                          GeneralStatus.error
                                      ? 'Intente actualizar las notificaciones.'
                                      : state.generalStatus ==
                                              GeneralStatus.loading
                                          ? 'Cargando notificaciones…'
                                          : 'No hay notificaciones.'))
                              : ListView(children: [
                                  for (final item in items)
                                    ListTile(
                                        leading: Icon(item.isRead
                                            ? Icons.notifications_none
                                            : Icons.mark_email_unread_outlined),
                                        title: Text(item.title,
                                            style: TextStyle(
                                                fontWeight: item.isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.bold)),
                                        subtitle: Text(
                                            '${item.message}\n${institutionalDate(item.createdAt)}',
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis),
                                        trailing: item.isRead
                                            ? null
                                            : IconButton(
                                                tooltip: 'Marcar leída',
                                                onPressed: state.busy
                                                    ? null
                                                    : () =>
                                                        cubit.markRead(item.id),
                                                icon: const Icon(Icons.done)),
                                        onTap: state.busy
                                            ? null
                                            : () async {
                                                if (!item.isRead &&
                                                    !await cubit.markRead(
                                                        item.id)) return;
                                                final owner =
                                                    widget.ownerContext;
                                                if (!context.mounted ||
                                                    !owner.mounted) return;
                                                if (item.correspondenceId !=
                                                    null) {
                                                  Navigator.pop(context);
                                                  if (widget.openDetail !=
                                                      null) {
                                                    await widget.openDetail!(
                                                        owner,
                                                        item.correspondenceId!);
                                                  } else {
                                                    await Navigator.of(owner)
                                                        .push(MaterialPageRoute<
                                                                void>(
                                                            builder: (_) =>
                                                                CorrespondenceDetailPage(
                                                                    correspondenceId:
                                                                        item.correspondenceId!)));
                                                  }
                                                  await cubit.refreshCount();
                                                  await widget.onReturn?.call();
                                                }
                                              })
                                ])),
                      if ((state.data?.totalPages ?? 0) > 1)
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                  tooltip: 'Anterior',
                                  onPressed: (state.data?.page ?? 1) > 1
                                      ? () => cubit.refresh(
                                          page: state.data!.page - 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_left)),
                              Text(
                                  '${state.data?.page ?? 1} / ${state.data?.totalPages ?? 0}'),
                              IconButton(
                                  tooltip: 'Siguiente',
                                  onPressed:
                                      state.data!.page < state.data!.totalPages
                                          ? () => cubit.refresh(
                                              page: state.data!.page + 1)
                                          : null,
                                  icon: const Icon(Icons.chevron_right))
                            ]),
                    ]);
              }))));
}
