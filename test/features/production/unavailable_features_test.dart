import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/features/reports/views/reports_page.dart';
import 'package:correspondencia_sipe_sipe/features/public_consult/views/public_consult_page.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/views/inbox_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth implements repo.AuthenticationRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('bandejas heredadas no activan datos de demostración',
      (tester) async {
    for (final type in [
      InboxType.received,
      InboxType.observed,
      InboxType.archived
    ]) {
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: InboxPage(inboxType: type))));
      expect(find.textContaining('todavía no está disponible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('reportes sin permiso no solicitan ni simulan datos',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        builder: ResponsiveBreakpointsConfig.builder,
        home: BlocProvider(
            create: (_) => AppSessionCubit(authRepository: _Auth()),
            child: const Scaffold(body: Column(children: [ReportsPage()])))));
    expect(find.text('Acceso restringido'), findsOneWidget);
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
