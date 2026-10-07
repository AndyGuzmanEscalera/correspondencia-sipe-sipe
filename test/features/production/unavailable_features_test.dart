import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/features/reports/views/reports_page.dart';
import 'package:correspondencia_sipe_sipe/features/public_consult/views/public_consult_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reportes no presentan cifras ni exportaciones simuladas',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        builder: ResponsiveBreakpointsConfig.builder,
        home: const Scaffold(body: Column(children: [ReportsPage()]))));
    expect(find.textContaining('todavía no están disponibles'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsNothing);
    expect(find.text('Total correspondencias'), findsNothing);
  });
  testWidgets(
      'consulta pública no solicita datos ni entrega resultados simulados',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        builder: ResponsiveBreakpointsConfig.builder,
        home: const PublicConsultPage()));
    expect(find.text('Consulta pública no disponible'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Resultado encontrado'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
