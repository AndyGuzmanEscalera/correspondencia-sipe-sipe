import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/institutional_date.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_page.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/metric_tile.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => MultiBlocProvider(providers: [
        BlocProvider(create: (_) => getIt<DashboardCubit>()),
        BlocProvider(create: (_) => getIt<CorrespondenceCubit>()),
      ], child: const DashboardView());
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocListener<SideMenuCubit, SideMenuState>(
          listenWhen: (previous, current) => previous.menus != current.menus,
          listener: (context, _) => context.read<DashboardCubit>().refresh(),
          child: FullWidgetGeneric(
              onInit: () => context.read<DashboardCubit>().init(),
              child: const DashboardBody()));
}

class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key});
  @override
  Widget build(BuildContext context) {
    final permissions =
        context.watch<AppSessionCubit>().state.userSession?.permissions ?? [];
    final sideMenu = context.read<SideMenuCubit>();
    return AdminContent(
        child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(
          title: 'Inicio',
          subtitle: 'Resumen de su correspondencia visible',
          actions: [
            IconButton(
                tooltip: 'Actualizar',
                onPressed: () async {
                  await context.read<DashboardCubit>().refresh();
                  await sideMenu.refreshBadges();
                },
                icon: const Icon(Icons.refresh_rounded))
          ]),
      const SizedBox(height: 20),
      BlocBuilder<DashboardCubit, DashboardState>(builder: (context, state) {
        final loading = state.generalStatus == GeneralStatus.loading;
        Widget metric(
                String title, int? value, IconData icon, VoidCallback? tap) =>
            MetricTile(
                title: title,
                value: state.displayCount(value, isLoading: loading),
                icon: icon,
                color: UiColors.primary,
                softColor: UiColors.primarySoft,
                onTap: tap);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (loading) const LinearProgressIndicator(),
          if (state.generalStatus == GeneralStatus.error)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(state.dialogMessage.message,
                    style: const TextStyle(color: UiColors.danger))),
          Wrap(spacing: 18, runSpacing: 18, children: [
            metric(
                'Mis documentos pendientes',
                state.mineCount,
                Icons.inbox_outlined,
                () => sideMenu.navigateToInbox(scope: repo.InboxScope.mine)),
            if (state.canViewUnit)
              metric('De mi unidad', state.unitCount, Icons.groups_outlined,
                  () => sideMenu.navigateToInbox(scope: repo.InboxScope.unit)),
            metric('Enviados', state.sentCount, Icons.send_outlined,
                sideMenu.navigateToSent),
            metric(
                'Concluidos',
                state.concludedCount,
                Icons.check_circle_outline,
                permissions.contains('reports.view')
                    ? () => sideMenu.navigateToMenu(MenuEnum.reports)
                    : null),
            metric('Total relevante', state.totalCount, Icons.folder_outlined,
                null),
          ]),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 12, children: [
            if (permissions.contains('correspondence.create'))
              FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva correspondencia'),
                  onPressed: () => _create(context)),
            if (sideMenu.state.menus.any((m) =>
                !m.isSection &&
                m.requiredPermission?.startsWith('master_data.') == true))
              OutlinedButton.icon(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Administración'),
                  onPressed: () {
                    final menu = sideMenu.state.menus.firstWhere((m) =>
                        !m.isSection &&
                        m.requiredPermission?.startsWith('master_data.') ==
                            true);
                    sideMenu.select(menu);
                  }),
            if (permissions.contains('reports.view'))
              OutlinedButton.icon(
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Reportes'),
                  onPressed: () => sideMenu.navigateToMenu(MenuEnum.reports)),
          ]),
          const SizedBox(height: 24),
          Text('Actividad reciente',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (state.activity.isEmpty &&
              state.generalStatus == GeneralStatus.success)
            const Text('Sin actividad reciente en su alcance.'),
          for (final item in state.activity)
            Card(
                child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.history),
                    title: Text('${_event(item.type)} · ${item.routeNumber}'),
                    subtitle: Text(
                        '${item.subject}\n${institutionalDate(item.createdAt)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => CorrespondenceDetailPage(
                              correspondenceId: item.correspondenceId)));
                      if (context.mounted) {
                        await context.read<DashboardCubit>().refresh();
                        await sideMenu.refreshBadges();
                      }
                    })),
        ]);
      }),
    ])));
  }

  String _event(String type) =>
      const {
        'RECEIVED': 'Recibida',
        'DERIVED': 'Derivada',
        'CONCLUDED': 'Concluida',
        'REOPENED': 'Reabierta'
      }[type] ??
      type;
  Future<void> _create(BuildContext context) => showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
          value: context.read<CorrespondenceCubit>(),
          child: UpsertCorrespondencePage(
              typeOperation: TypeOperation.create,
              hostDialogContext: dialogContext,
              ownerContext: context)));
}
