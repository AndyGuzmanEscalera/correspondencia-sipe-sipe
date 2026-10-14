import 'dart:async';
import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/platform/file_download_service.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/features/reports/cubit/reports_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/reports/views/reports_page.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/helpers/menu_options.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_helpers/final_block_fixtures.dart';

class _Download implements FileDownloadService {
  List<int>? bytes;
  String? filename, mime;
  @override
  Future<void> downloadBytes(
      {required String filename,
      required List<int> bytes,
      String? mimeType}) async {
    this.bytes = bytes;
    this.filename = filename;
    mime = mimeType;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeReports repository;
  late ReportsCubit cubit;
  late _Download download;
  setUp(() {
    repository = FakeReports();
    download = _Download();
    cubit = ReportsCubit(repository, download: download);
  });
  tearDown(() async {
    await cubit.close();
  });
  Future<void> pump(WidgetTester tester,
      {double width = 1200, bool load = true}) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        builder: ResponsiveBreakpointsConfig.builder,
        home: BlocProvider.value(
            value: cubit,
            child: const Scaffold(body: Column(children: [ReportsBody()])))));
    if (load) await cubit.init();
    await tester.pumpAndSettle();
  }

  testWidgets('real table and backend summaries', (tester) async {
    await pump(tester);
    expect(find.text('HR-QA-1'), findsOneWidget);
    expect(find.textContaining('Pendientes: 40'), findsOneWidget);
    expect(find.textContaining('NOTA: 41'), findsOneWidget);
  });
  testWidgets('no unit scope hides unit filter', (tester) async {
    await pump(tester);
    expect(find.text('Unidad actual'), findsNothing);
  });
  testWidgets('unit scope shows useful unit and employee filters',
      (tester) async {
    repository.configuration = const repo.ReportOptions(
        types: [],
        units: [repo.ReportOption(id: 'u1', name: 'Unidad QA')],
        employees: [repo.ReportOption(id: 'e1', name: 'Funcionario QA')],
        canViewUnit: true);
    await pump(tester);
    expect(find.text('Unidad actual'), findsOneWidget);
    expect(find.text('Funcionario responsable'), findsOneWidget);
  });
  testWidgets('applies dates search and resets pagination', (tester) async {
    await pump(tester);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Fecha desde'), '2026-10-01');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Fecha hasta'), '2026-10-14');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Hoja de ruta / referencia'),
        'HR-QA');
    await tester.ensureVisible(find.text('Aplicar filtros'));
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();
    final call = repository.calls.last;
    expect(call.filter.dateFrom, '2026-10-01');
    expect(call.filter.dateTo, '2026-10-14');
    expect(call.filter.search, 'HR-QA');
    expect(call.page, 1);
  });
  testWidgets('invalid date prevents request', (tester) async {
    await pump(tester);
    final before = repository.calls.length;
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Fecha desde'), '2026-99-99');
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();
    expect(repository.calls.length, before);
    expect(find.text('Use AAAA-MM-DD'), findsOneWidget);
  });
  testWidgets('empty result displays actual zero', (tester) async {
    repository.result = Ok(reportData(empty: true));
    await pump(tester);
    expect(find.text('No hay correspondencias para los filtros aplicados.'),
        findsOneWidget);
    expect(find.textContaining('Total: 0'), findsOneWidget);
  });
  testWidgets('error offers refresh instead of false zero', (tester) async {
    repository.result = const Err(ServerFailure('Backend QA error'));
    await pump(tester);
    expect(find.textContaining('Total: —'), findsOneWidget);
    expect(find.byTooltip('Actualizar reporte'), findsOneWidget);
    expect(find.text('No hay correspondencias para los filtros aplicados.'),
        findsNothing);
  });
  testWidgets('loading is visible', (tester) async {
    final pending = Completer<Result<repo.ReportPage, Failure>>();
    repository.pending = pending.future;
    await pump(tester, load: false);
    final request = cubit.init();
    await tester.pump();
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    pending.complete(Ok(reportData()));
    await request;
    await tester.pumpAndSettle();
  });
  testWidgets('export uses applied filters not edited draft', (tester) async {
    await pump(tester);
    await cubit.load(
        filter: const repo.ReportFilter(kind: 'received', status: 'ACTIVE'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Hoja de ruta / referencia'),
        'UNAPPLIED');
    await tester.ensureVisible(find.text('Exportar'));
    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();
    expect(repository.exported!.kind, 'received');
    expect(repository.exported!.status, 'ACTIVE');
    expect(repository.exported!.search, isNull);
    expect(download.bytes, [65, 66]);
  });
  test('pagination retains server filters', () async {
    await cubit.init();
    const filter =
        repo.ReportFilter(kind: 'sent', search: 'QA', documentTypeId: 't1');
    await cubit.load(filter: filter);
    await cubit.load(page: 2);
    expect(repository.calls.last.page, 2);
    expect(repository.calls.last.filter, same(filter));
    await cubit.load(pageSize: 50);
    expect(repository.calls.last.page, 1);
    expect(repository.calls.last.size, 50);
  });
  test('out of order responses cannot overwrite newer filters', () async {
    final old = Completer<Result<repo.ReportPage, Failure>>();
    repository.pending = old.future;
    final first =
        cubit.load(filter: const repo.ReportFilter(kind: 'registered'));
    repository.pending = null;
    await cubit.load(filter: const repo.ReportFilter(kind: 'received'));
    old.complete(Ok(reportData()));
    await first;
    expect(cubit.state.filter.kind, 'received');
  });
  testWidgets('mobile report does not overflow', (tester) async {
    await pump(tester, width: 390);
    expect(tester.takeException(), isNull);
  });
  test('report menu requires dynamic grant', () {
    expect(
        MenuOptions.build(counts: const {}, permissions: [])
            .any((m) => m.menu == MenuEnum.reports),
        isFalse);
    expect(
        MenuOptions.build(counts: const {}, permissions: ['reports.view'])
            .any((m) => m.menu == MenuEnum.reports),
        isTrue);
  });
  for (final format in repo.ReportFormat.values) {
    testWidgets(
        'Exportar menú descarga ${format.extension} con filtros aplicados',
        (tester) async {
      await pump(tester);
      await cubit.load(
          filter: const repo.ReportFilter(
              kind: 'received',
              dateFrom: '2026-10-01',
              dateTo: '2026-10-31',
              status: 'ACTIVE'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Exportar'));
      await tester.tap(find.text('Exportar'));
      await tester.pumpAndSettle();
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('Excel (.xlsx)'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      await tester.tap(find.text(format.label));
      await tester.pumpAndSettle();
      expect(repository.exportedFormat, format);
      expect(repository.exported!.status, 'ACTIVE');
      expect(download.filename,
          'reporte_recibidos_2026-10-01_2026-10-31.${format.extension}');
      expect(download.mime, format.mimeType);
      expect(download.bytes, [65, 66]);
    });
    test('export ${format.extension} loading y Failure no descargan bytes',
        () async {
      await cubit.init();
      final waiting = Completer<Result<List<int>, Failure>>();
      repository.pendingExport = waiting.future;
      final request = cubit.export(format: format);
      expect(cubit.state.exporting, isTrue);
      waiting.complete(const Err(ServerFailure('Error de generación QA')));
      await request;
      expect(cubit.state.exporting, isFalse);
      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(download.bytes, isNull);
    });
  }
  testWidgets('generación muestra indicador y bloquea exportación duplicada',
      (tester) async {
    await pump(tester);
    final pending = Completer<Result<List<int>, Failure>>();
    repository.pendingExport = pending.future;
    final request = cubit.export(format: repo.ReportFormat.pdf);
    await tester.pump();
    await tester.pump();
    expect(find.text('Exportando…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
        tester
            .widget<PopupMenuButton<repo.ReportFormat>>(
                find.byType(PopupMenuButton<repo.ReportFormat>))
            .enabled,
        isFalse);
    pending.complete(const Ok([65]));
    await request;
    await tester.pumpAndSettle();
  });
}
