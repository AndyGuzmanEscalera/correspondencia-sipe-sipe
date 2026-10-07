import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Pendiente de un contrato backend y de autorización para reportes.
/// El panel operativo usa datos reales; esta pantalla no debe simular totales.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override
  Widget build(BuildContext context) => const ReportsView();
}

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});
  @override
  Widget build(BuildContext context) => const ReportsBody();
}

class ReportsBody extends StatelessWidget {
  const ReportsBody({super.key});
  @override
  Widget build(BuildContext context) => const AdminContent(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: 'Reporte general', subtitle: 'Reportes institucionales'),
          SizedBox(height: 24),
          Text(
              'Los reportes institucionales y su exportación todavía no están disponibles. Consulte el Panel para ver los indicadores operativos actuales.'),
        ],
      ));
}
