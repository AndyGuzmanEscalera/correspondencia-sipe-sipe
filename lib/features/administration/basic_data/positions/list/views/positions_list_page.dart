import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list/cubit/positions_list_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_status_badge.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/form_save_error.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PositionsListPage extends StatelessWidget {
  const PositionsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PositionsListCubit>()..init(),
      child: const PositionsListView(),
    );
  }
}

class PositionsListView extends StatelessWidget {
  const PositionsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<PositionsListCubit, PositionsListState>().listen(),
      ],
      child: const PositionsListBody(),
    );
  }
}

class PositionsListBody extends StatelessWidget {
  const PositionsListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    final canManage = hasPermission(session, Permissions.positionsManage);
    final cubit = context.read<PositionsListCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Cargos',
            subtitle: 'Catálogo de cargos institucionales',
            actions: [
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo cargo'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar por código o nombre',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          DataPanel(
            child: BlocBuilder<PositionsListCubit, PositionsListState>(
              builder: (context, state) {
                return AppDataGrid<PositionAdmin>(
                  items: state.items,
                  isLoading: state.listLoading ||
                      (state.items.isEmpty &&
                          state.generalStatus == GeneralStatus.loading),
                  emptyMessage: 'No se encontraron registros con ese criterio.',
                  columns: [
                    AppDataGridColumn<PositionAdmin>(
                      key: 'code',
                      label: 'Código',
                      width: 120,
                      value: (item) => item.code,
                      mobilePriority: 20,
                    ),
                    AppDataGridColumn<PositionAdmin>(
                      key: 'name',
                      label: 'Nombre',
                      value: (item) => item.name,
                      mobilePrimary: true,
                      mobilePriority: 1,
                    ),
                    AppDataGridColumn<PositionAdmin>(
                      key: 'description',
                      label: 'Descripción',
                      value: (item) => item.description,
                      mobilePriority: 40,
                    ),
                    AppDataGridColumn<PositionAdmin>(
                      key: 'active',
                      label: 'Estado',
                      type: AppDataGridCellType.status,
                      width: 110,
                      value: (item) => item.isActive,
                      mobilePriority: 5,
                      cellBuilder: (context, item, value) {
                        final active = value == true;
                        return active
                            ? const AppStatusBadge.success('Activo')
                            : const AppStatusBadge.inactive('Inactivo');
                      },
                    ),
                  ],
                  actions: canManage
                      ? [
                          AppDataGridAction<PositionAdmin>(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar',
                            onPressed: (item) =>
                                _showFormDialog(context, item: item),
                          ),
                          AppDataGridAction<PositionAdmin>(
                            icon: Icons.toggle_on_outlined,
                            tooltip: 'Activar/desactivar',
                            visibleWhen: (item) => item.isActive,
                            onPressed: cubit.toggleActive,
                          ),
                          AppDataGridAction<PositionAdmin>(
                            icon: Icons.toggle_off_outlined,
                            tooltip: 'Activar/desactivar',
                            visibleWhen: (item) => !item.isActive,
                            onPressed: cubit.toggleActive,
                          ),
                        ]
                      : const [],
                  currentPage: state.page,
                  pageSize: state.pageSize,
                  totalItems: state.total,
                  totalPages: state.totalPages,
                  onPageChanged: cubit.changePage,
                  onPageSizeChanged: cubit.changePageSize,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFormDialog(BuildContext context, {PositionAdmin? item}) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<PositionsListCubit>(),
        child: _PositionFormDialog(item: item),
      ),
    );
  }
}

class _PositionFormDialog extends StatefulWidget {
  const _PositionFormDialog({this.item});
  final PositionAdmin? item;

  @override
  State<_PositionFormDialog> createState() => _PositionFormDialogState();
}

class _PositionFormDialogState extends State<_PositionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final ControllerFieldPro _code;
  late final ControllerFieldPro _name;
  late final ControllerFieldPro _description;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    _code = ControllerFieldPro()..setValue(widget.item?.code ?? '');
    _name = ControllerFieldPro()..setValue(widget.item?.name ?? '');
    _description = ControllerFieldPro()
      ..setValue(widget.item?.description ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FullWidgetGeneric(
      onDispose: () {},
      child: BlocBuilder<PositionsListCubit, PositionsListState>(
        builder: (context, state) {
          return AlertDialog(
            title: Text(_isEdit ? 'Editar cargo' : 'Nuevo cargo'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FormSaveError(message: state.saveError),
                    AppTextField(
                      controller: _code,
                      label: 'Código',
                      readOnly: _isEdit,
                      validators: [RequiredValid(error: 'Campo requerido')],
                    ),
                    AppTextField(
                      controller: _name,
                      label: 'Nombre',
                      validators: [RequiredValid(error: 'Campo requerido')],
                    ),
                    AppTextField(
                      controller: _description,
                      label: 'Descripción (opcional)',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: state.saveInProgress ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: state.saveInProgress ? null : _submit,
                child: state.saveInProgress
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Guardar' : 'Registrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.validateForm()) return;
    final success = await context.read<PositionsListCubit>().save(
          id: widget.item?.id,
          code: _code.getValue(),
          name: _name.getValue(),
          description: _description.getValue(),
        );
    if (success && mounted) Navigator.pop(context);
  }
}
