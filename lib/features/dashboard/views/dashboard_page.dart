import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/official_logo.dart';
import 'package:correspondencia_sipe_sipe/core/auth/session_header_labels.dart';
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
    final session = context.watch<AppSessionCubit>().state.userSession;
    final permissions = session?.permissions ?? [];
    final labels = SessionHeaderLabels.forSession(session, compact: false);
    final sideMenu = context.read<SideMenuCubit>();
    return AdminContent(
        child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, box) {
        final compact = box.maxWidth < 680;
        final information =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (compact)
            const Text(OfficialLogo.institution,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Text(OfficialLogo.system,
              style: TextStyle(
                  fontSize: compact ? 13 : 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Bienvenido/a, ${labels.primaryLine}',
              style: const TextStyle(fontSize: 13)),
          if (labels.secondaryLine.isNotEmpty)
            Text(labels.secondaryLine,
                style: const TextStyle(
                    color: UiColors.textSecondary, fontSize: 12)),
        ]);
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          OfficialLogo(compact: compact, width: compact ? 48 : 310),
          SizedBox(width: compact ? 12 : 28),
          Expanded(child: information),
        ]);
      }),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(
            child: Text('Resumen de correspondencia',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600))),
        IconButton(
            tooltip: 'Actualizar',
            onPressed: () async {
              await context.read<DashboardCubit>().refresh();
              await sideMenu.refreshBadges();
            },
            icon: const Icon(Icons.refresh_rounded, size: 20)),
      ]),
      const SizedBox(height: 8),
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
          LayoutBuilder(builder: (context, constraints) {
            final columns = ((constraints.maxWidth + 12) / 195)
                .floor()
                .clamp(1, state.canViewUnit ? 5 : 4);
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  metric(
                      'Mis documentos pendientes',
                      state.mineCount,
                      Icons.inbox_outlined,
                      () => sideMenu.navigateToInbox(
                          scope: repo.InboxScope.mine)),
                  if (state.canViewUnit)
                    metric(
                        'De mi unidad',
                        state.unitCount,
                        Icons.groups_outlined,
                        () => sideMenu.navigateToInbox(
                            scope: repo.InboxScope.unit)),
                  metric('Enviados', state.sentCount, Icons.send_outlined,
                      sideMenu.navigateToSent),
                  metric(
                      'Concluidos',
                      state.concludedCount,
                      Icons.check_circle_outline,
                      permissions.contains('reports.view')
                          ? () => sideMenu.navigateToMenu(MenuEnum.reports)
                          : null),
                  metric('Total relevante', state.totalCount,
                      Icons.folder_outlined, null),
                ].map((tile) => SizedBox(width: width, child: tile)).toList());
          }),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 12, children: [
            if (canCreateCorrespondence(permissions))
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
          if (state.activity.isNotEmpty)
            Container(
                decoration: BoxDecoration(
                    color: UiColors.surface,
                    border: Border.all(color: UiColors.border),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  for (var index = 0;
                      index < state.activity.length;
                      index++) ...[
                    if (index > 0)
                      const Divider(height: 1, color: UiColors.borderLight),
                    _ActivityRow(
                        item: state.activity[index],
                        label: _event(state.activity[index].type),
                        onTap: () async {
                          await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => CorrespondenceDetailPage(
                                      correspondenceId: state
                                          .activity[index].correspondenceId)));
                          if (context.mounted) {
                            await context.read<DashboardCubit>().refresh();
                            await sideMenu.refreshBadges();
                          }
                        }),
                  ]
                ])),
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

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(
      {required this.item, required this.label, required this.onTap});
  final repo.RecentActivity item;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final narrow = box.maxWidth < 620;
        final detail =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(item.routeNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(label,
                    style:
                        const TextStyle(color: UiColors.primary, fontSize: 12)),
              ]),
          const SizedBox(height: 3),
          Text(item.subject,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: UiColors.textSecondary, fontSize: 13)),
          if (narrow)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(institutionalDate(item.createdAt),
                    style: const TextStyle(
                        color: UiColors.textSecondary, fontSize: 11))),
        ]);
        return Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Expanded(child: detail),
                      if (!narrow)
                        Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(institutionalDate(item.createdAt),
                                style: const TextStyle(
                                    color: UiColors.textSecondary,
                                    fontSize: 12))),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right,
                          size: 18, color: UiColors.textSecondary),
                    ]))));
      });
}
