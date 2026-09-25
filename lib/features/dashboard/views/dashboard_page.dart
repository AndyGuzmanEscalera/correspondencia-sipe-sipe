import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_device.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardCubit>(),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<DashboardCubit, DashboardState>().listen(
          showSuccess: false,
        ),
      ],
      child: FullWidgetGeneric(
        onInit: () => context.read<DashboardCubit>().init(),
        child: const DashboardBody(),
      ),
    );
  }
}

class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminContent(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Panel de control',
              subtitle:
                  'Visión general del flujo de correspondencia institucional',
              actions: [
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: () => context.read<DashboardCubit>().refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 28),
            BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                final isLoading =
                    state.generalStatus == GeneralStatus.loading &&
                        state.mineCount == null &&
                        state.unitCount == null &&
                        state.sentCount == null;
                final sideMenu = context.read<SideMenuCubit>();

                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    MetricTile(
                      title: 'Asignados a mí',
                      value: state.displayCount(
                        state.mineCount,
                        isLoading: isLoading,
                      ),
                      icon: Icons.inbox_outlined,
                      color: UiColors.info,
                      softColor: UiColors.infoSoft,
                      onTap: () => sideMenu.navigateToInbox(
                        scope: repo.InboxScope.mine,
                      ),
                    ),
                    MetricTile(
                      title: 'De mi unidad',
                      value: state.displayCount(
                        state.unitCount,
                        isLoading: isLoading,
                      ),
                      icon: Icons.groups_outlined,
                      color: UiColors.primary,
                      softColor: UiColors.primarySoft,
                      onTap: () => sideMenu.navigateToInbox(
                        scope: repo.InboxScope.unit,
                      ),
                    ),
                    MetricTile(
                      title: 'Enviados',
                      value: state.displayCount(
                        state.sentCount,
                        isLoading: isLoading,
                      ),
                      icon: Icons.send_outlined,
                      color: UiColors.success,
                      softColor: UiColors.successSoft,
                      onTap: sideMenu.navigateToSent,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: AppDecorations.surfaceCard(),
              child: context.isSmallScreen
                  ? const _OverviewPanel()
                  : const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _OverviewPanel()),
                        SizedBox(width: 24),
                        _OverviewIcon(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen operativo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Seguimiento centralizado de correspondencia entrante, saliente y trámites '
          'en curso dentro de la institución.',
        ),
        const SizedBox(height: 20),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _FeatureChip('Consulta pública'),
            _FeatureChip('Bandejas operativas'),
            _FeatureChip('Registro de trámites'),
            _FeatureChip('Reportes institucionales'),
          ],
        ),
      ],
    );
  }
}

class _OverviewIcon extends StatelessWidget {
  const _OverviewIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [UiColors.primarySoft, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDecorations.borderRadiusLg,
      ),
      child: const Icon(
        Icons.auto_graph_rounded,
        size: 72,
        color: UiColors.primary,
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: UiColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: UiColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: UiColors.textPrimary,
        ),
      ),
    );
  }
}
