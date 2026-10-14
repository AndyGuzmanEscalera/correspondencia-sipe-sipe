import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/auth/permission_guard.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/institutional_date.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_page.dart';
import 'package:correspondencia_sipe_sipe/features/reports/cubit/reports_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});
  @override
  Widget build(BuildContext context) => PermissionGuard(
      permission: 'reports.view',
      child: BlocProvider(
          create: (_) => getIt<ReportsCubit>(), child: const ReportsView()));
}

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});
  @override
  Widget build(BuildContext context) => FullWidgetGeneric(
      onInit: () => context.read<ReportsCubit>().init(),
      child: const ReportsBody());
}

class ReportsBody extends StatefulWidget {
  const ReportsBody({super.key});
  @override
  State<ReportsBody> createState() => _ReportsBodyState();
}

class _ReportsBodyState extends State<ReportsBody> {
  final _form = GlobalKey<FormState>();
  final _from = TextEditingController(),
      _to = TextEditingController(),
      _search = TextEditingController();
  String _kind = 'registered';
  String? _type, _status, _unit, _employee;
  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _search.dispose();
    super.dispose();
  }

  String? _dateValidation(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value.trim());
    return parsed == null ||
            DateFormat('yyyy-MM-dd').format(parsed) != value.trim()
        ? 'Use AAAA-MM-DD'
        : null;
  }

  Widget _date(String label, TextEditingController controller) => SizedBox(
      width: 190,
      child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
              labelText: label,
              hintText: 'AAAA-MM-DD',
              suffixIcon: IconButton(
                  tooltip: 'Elegir $label',
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(controller.text) ??
                            DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (date != null)
                      controller.text = DateFormat('yyyy-MM-dd').format(date);
                  })),
          validator: _dateValidation));
  Widget _options(String label, List<repo.ReportOption> values,
          String? selected, ValueChanged<String?> onChange) =>
      SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
              value: selected,
              isExpanded: true,
              decoration: InputDecoration(labelText: label),
              hint: const Text('Todos'),
              items: [
                const DropdownMenuItem<String>(child: Text('Todos')),
                for (final item in values)
                  DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name, overflow: TextOverflow.ellipsis))
              ],
              onChanged: onChange));
  void _apply() {
    if (!_form.currentState!.validate()) return;
    if (_from.text.isNotEmpty &&
        _to.text.isNotEmpty &&
        _from.text.compareTo(_to.text) > 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('La fecha desde no puede ser posterior a la fecha hasta')));
      return;
    }
    context.read<ReportsCubit>().load(
        filter: repo.ReportFilter(
            kind: _kind,
            dateFrom: _from.text.trim().isEmpty ? null : _from.text.trim(),
            dateTo: _to.text.trim().isEmpty ? null : _to.text.trim(),
            documentTypeId: _type,
            status: _status,
            unitId: _unit,
            employeeId: _employee,
            search: _search.text));
  }

  @override
  Widget build(BuildContext context) => AdminContent(child:
          BlocBuilder<ReportsCubit, ReportsState>(builder: (context, state) {
        final cubit = context.read<ReportsCubit>();
        final data = state.data;
        final loading = state.generalStatus == GeneralStatus.loading;
        final compact = MediaQuery.sizeOf(context).width < 768;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                  title: 'Reportes',
                  subtitle: 'Correspondencia dentro de su alcance de lectura',
                  actions: [
                    IconButton(
                        tooltip: 'Actualizar reporte',
                        onPressed: cubit.refresh,
                        icon: const Icon(Icons.refresh))
                  ]),
              const SizedBox(height: 12),
              ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: compact ? 280 : 200),
                  child: SingleChildScrollView(
                      child: Form(
                          key: _form,
                          child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                    width: 220,
                                    child: DropdownButtonFormField<String>(
                                        value: _kind,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Reporte'),
                                        items: [
                                          for (final item in const {
                                            'registered': 'Registrada',
                                            'received': 'Recibida',
                                            'sent': 'Enviada',
                                            'concluded': 'Concluida'
                                          }.entries)
                                            DropdownMenuItem(
                                                value: item.key,
                                                child: Text(item.value))
                                        ],
                                        onChanged: (value) =>
                                            setState(() => _kind = value!))),
                                _date('Fecha desde', _from),
                                _date('Fecha hasta', _to),
                                _options(
                                    'Tipo documental',
                                    state.options?.types ?? [],
                                    _type,
                                    (value) => setState(() => _type = value)),
                                SizedBox(
                                    width: 190,
                                    child: DropdownButtonFormField<String>(
                                        value: _status,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Estado'),
                                        hint: const Text('Todos'),
                                        items: const [
                                          DropdownMenuItem<String>(
                                              child: Text('Todos')),
                                          DropdownMenuItem(
                                              value: 'ACTIVE',
                                              child: Text('Activa')),
                                          DropdownMenuItem(
                                              value: 'CONCLUDED',
                                              child: Text('Concluida'))
                                        ],
                                        onChanged: (value) =>
                                            setState(() => _status = value))),
                                if (state.options?.canViewUnit ?? false)
                                  _options(
                                      'Unidad actual',
                                      state.options!.units,
                                      _unit,
                                      (value) => setState(() => _unit = value)),
                                if (state.options?.employees.isNotEmpty ??
                                    false)
                                  _options(
                                      'Funcionario responsable',
                                      state.options!.employees,
                                      _employee,
                                      (value) =>
                                          setState(() => _employee = value)),
                                SizedBox(
                                    width: 260,
                                    child: TextFormField(
                                        controller: _search,
                                        decoration: const InputDecoration(
                                            labelText:
                                                'Hoja de ruta / referencia',
                                            hintText:
                                                'Buscar asunto, referencia o HR'),
                                        onFieldSubmitted: (_) => _apply())),
                                FilledButton(
                                    onPressed: loading ? null : _apply,
                                    child: const Text('Aplicar filtros')),
                                PopupMenuButton<repo.ReportFormat>(
                                    enabled: !loading &&
                                        !state.exporting &&
                                        data != null,
                                    tooltip: 'Elegir formato de exportación',
                                    onSelected: (format) =>
                                        cubit.export(format: format),
                                    itemBuilder: (_) => [
                                          for (final format
                                              in repo.ReportFormat.values)
                                            PopupMenuItem(
                                                value: format,
                                                child: Text(format.label))
                                        ],
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Theme.of(context)
                                                    .dividerColor),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (state.exporting)
                                                const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2))
                                              else
                                                Icon(Icons.download_outlined,
                                                    size: 18,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary),
                                              const SizedBox(width: 8),
                                              Text(state.exporting
                                                  ? 'Exportando…'
                                                  : 'Exportar'),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.expand_more,
                                                  size: 18),
                                            ]))),
                              ])))),
              const SizedBox(height: 12),
              if (loading) const LinearProgressIndicator(),
              if (state.generalStatus == GeneralStatus.error)
                Text(state.dialogMessage.message),
              Text(
                  'Filtros aplicados: ${const {
                    'registered': 'Registrada',
                    'received': 'Recibida',
                    'sent': 'Enviada',
                    'concluded': 'Concluida'
                  }[state.filter.kind]} · ${state.filter.dateFrom ?? 'Sin inicio'} / ${state.filter.dateTo ?? 'Sin fin'}',
                  style: Theme.of(context).textTheme.bodySmall),
              Text(
                  'Total: ${data?.summary.total ?? '—'} · Pendientes: ${data?.summary.pending ?? '—'} · Concluidas: ${data?.summary.concluded ?? '—'}',
                  style: Theme.of(context).textTheme.titleSmall),
              if (data != null)
                ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 70),
                    child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              'Por tipo: ${data.summary.byType.map((x) => '${x.name}: ${x.total}').join(' · ')}'),
                          if (data.summary.byUnit.isNotEmpty)
                            Text(
                                'Por unidad: ${data.summary.byUnit.map((x) => '${x.name}: ${x.total}').join(' · ')}'),
                        ]))),
              const SizedBox(height: 12),
              DataPanel(
                  child: AppDataGrid<repo.ReportRow>(
                      items: data?.items ?? [],
                      isLoading: loading && data == null,
                      emptyMessage: state.generalStatus == GeneralStatus.error
                          ? 'No se pudo cargar el reporte. Intente actualizar.'
                          : 'No hay correspondencias para los filtros aplicados.',
                      allowSorting: false,
                      columns: [
                        AppDataGridColumn(
                            key: 'route',
                            label: 'Hoja de ruta',
                            value: (row) => row.routeNumber,
                            mobilePrimary: true,
                            width: 155),
                        AppDataGridColumn(
                            key: 'date',
                            label: 'Fecha',
                            value: (row) => institutionalDate(row.date),
                            width: 160),
                        AppDataGridColumn(
                            key: 'type',
                            label: 'Tipo',
                            value: (row) => row.documentType),
                        AppDataGridColumn(
                            key: 'subject',
                            label: 'Asunto / referencia',
                            value: (row) => row.reference == null
                                ? row.subject
                                : '${row.subject} · ${row.reference}'),
                        AppDataGridColumn(
                            key: 'origin',
                            label: 'Origen',
                            value: (row) => row.origin),
                        AppDataGridColumn(
                            key: 'destination',
                            label: 'Destino actual',
                            value: (row) =>
                                '${row.destination ?? '—'} · ${row.employee ?? 'Sin funcionario'}'),
                        AppDataGridColumn(
                            key: 'status',
                            label: 'Estado',
                            value: (row) => row.status),
                      ],
                      currentPage: data?.page ?? 1,
                      pageSize: state.pageSize,
                      totalItems: data?.total ?? 0,
                      totalPages: data?.totalPages ?? 0,
                      onPageChanged: (page) => cubit.load(page: page),
                      onPageSizeChanged: (size) => cubit.load(pageSize: size),
                      onRowTap: (row) => _openDetail(context, row))),
            ]);
      }));
  Future<void> _openDetail(BuildContext context, repo.ReportRow row) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => CorrespondenceDetailPage(correspondenceId: row.id)));
    if (context.mounted) {
      await context.read<ReportsCubit>().refresh();
      await context.read<SideMenuCubit>().refreshBadges();
    }
  }
}
