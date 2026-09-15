import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportsView();
  }
}

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportsBody();
  }
}

class ReportsBody extends StatelessWidget {
  const ReportsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Reporte general',
            subtitle: 'Analítica operativa para control institucional',
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generando reporte PDF...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Exportar PDF'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _FilterBox(
                child: DropdownButtonFormField<String>(
                  value: '2026',
                  decoration: const InputDecoration(
                    labelText: 'Gestión',
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(value: '2026', child: Text('2026')),
                    DropdownMenuItem(value: '2025', child: Text('2025')),
                  ],
                  onChanged: (_) {},
                ),
              ),
              _FilterBox(
                child: DropdownButtonFormField<String>(
                  value: 'Todos',
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'Recibidos', child: Text('Recibidos')),
                    DropdownMenuItem(value: 'Enviados', child: Text('Enviados')),
                  ],
                  onChanged: (_) {},
                ),
              ),
              _FilterBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  value: store.units.first.name,
                  decoration: const InputDecoration(
                    labelText: 'Unidad',
                    border: InputBorder.none,
                  ),
                  items: store.units
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit.name,
                          child: Text(unit.name),
                        ),
                      )
                      .toList(),
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: AppDecorations.surfaceCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen operativo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _ReportRow(
                    label: 'Total correspondencias',
                    value: '${store.correspondences.length}',
                  ),
                  _ReportRow(
                    label: 'Correspondencia externa (CE)',
                    value: '${store.correspondences.where((e) => e.type.name == 'ce').length}',
                  ),
                  _ReportRow(
                    label: 'Correspondencia interna (CI)',
                    value: '${store.correspondences.where((e) => e.type.name == 'ci').length}',
                  ),
                  _ReportRow(
                    label: 'Unidades registradas',
                    value: '${store.units.length}',
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: UiColors.primarySoft,
                      borderRadius: AppDecorations.borderRadiusMd,
                    ),
                    child: const Text(
                      'Exporte reportes filtrados por gestión, unidad, cargo y estado '
                      'de la correspondencia institucional.',
                      style: TextStyle(color: UiColors.primary, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  const _FilterBox({required this.child, this.width = 220});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(color: UiColors.border),
      ),
      child: child,
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: UiColors.background,
        borderRadius: AppDecorations.borderRadiusSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: UiColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
