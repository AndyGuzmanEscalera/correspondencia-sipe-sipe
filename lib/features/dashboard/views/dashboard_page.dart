import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_device.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/metric_tile.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardView();
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardBody();
  }
}

class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    final counts = store.inboxCounts();

    return AdminContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Panel de control',
            subtitle: 'Visión general del flujo de correspondencia institucional',
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              MetricTile(
                title: 'Correspondencias',
                value: '${store.correspondences.length}',
                icon: Icons.description_outlined,
                color: UiColors.primary,
                softColor: UiColors.primarySoft,
              ),
              MetricTile(
                title: 'Recibidos',
                value: '${counts['received'] ?? 0}',
                icon: Icons.move_to_inbox_outlined,
                color: UiColors.info,
                softColor: UiColors.infoSoft,
              ),
              MetricTile(
                title: 'Enviados',
                value: '${counts['sent'] ?? 0}',
                icon: Icons.send_outlined,
                color: UiColors.success,
                softColor: UiColors.successSoft,
              ),
              MetricTile(
                title: 'Funcionarios',
                value: '${store.employees.length}',
                icon: Icons.badge_outlined,
                color: UiColors.warning,
                softColor: UiColors.warningSoft,
              ),
            ],
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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
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
