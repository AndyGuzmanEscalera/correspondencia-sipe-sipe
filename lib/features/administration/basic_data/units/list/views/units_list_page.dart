import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list/cubit/units_list_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_status_badge.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/form_save_error.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnitsListPage extends StatelessWidget {
  const UnitsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UnitsListCubit>()..init(),
      child: const UnitsListView(),
    );
  }
}

class UnitsListView extends StatelessWidget {
  const UnitsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<UnitsListCubit, UnitsListState>().listen(),
      ],
      child: const UnitsListBody(),
    );
  }
}

class UnitsListBody extends StatelessWidget {
  const UnitsListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    final canManage = hasPermission(session, Permissions.organizationalUnitsManage);
    final cubit = context.read<UnitsListCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Unidades organizacionales',
            subtitle: 'Estructura orgánica institucional',
            actions: [
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva unidad'),
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
            child: BlocBuilder<UnitsListCubit, UnitsListState>(
              builder: (context, state) {
                return AppDataGrid<OrganizationalUnitAdmin>(
                  items: state.items,
                  isLoading: state.listLoading ||
                      (state.items.isEmpty &&
                          state.generalStatus == GeneralStatus.loading),
                  emptyMessage: 'No se encontraron registros con ese criterio.',
                  columns: [
                    AppDataGridColumn<OrganizationalUnitAdmin>(
                      key: 'code',
                      label: 'Código',
                      width: 120,
                      value: (item) => item.code,
                      mobilePriority: 20,
                    ),
                    AppDataGridColumn<OrganizationalUnitAdmin>(
                      key: 'name',
                      label: 'Nombre',
                      value: (item) => item.name,
                      mobilePrimary: true,
                      mobilePriority: 1,
                    ),
                    AppDataGridColumn<OrganizationalUnitAdmin>(
                      key: 'parent',
                      label: 'Unidad superior',
                      value: (item) => item.parentName,
                      mobilePriority: 15,
                    ),
                    AppDataGridColumn<OrganizationalUnitAdmin>(
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
                          AppDataGridAction<OrganizationalUnitAdmin>(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar',
                            onPressed: (item) =>
                                _showFormDialog(context, item: item),
                          ),
                          AppDataGridAction<OrganizationalUnitAdmin>(
                            icon: Icons.toggle_on_outlined,
                            tooltip: 'Activar/desactivar',
                            visibleWhen: (item) => item.isActive,
                            onPressed: cubit.toggleActive,
                          ),
                          AppDataGridAction<OrganizationalUnitAdmin>(
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

  Future<void> _showFormDialog(
    BuildContext context, {
    OrganizationalUnitAdmin? item,
  }) {
    final cubit = context.read<UnitsListCubit>();
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _UnitFormDialog(item: item),
      ),
    );
  }
}

class _UnitFormDialog extends StatefulWidget {
  const _UnitFormDialog({this.item});
  final OrganizationalUnitAdmin? item;

  @override
  State<_UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<_UnitFormDialog> {
  static const _noParent = FormOption<String>(
    id: 0,
    text: 'Sin unidad superior',
    value: '',
  );

  final _formKey = GlobalKey<FormState>();
  late final ControllerFieldPro _code;
  late final ControllerFieldPro _name;
  late final ControllerFieldPro _description;
  late final ControllerFieldDropdown<String> _parent;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    _code = ControllerFieldPro()..setValue(widget.item?.code ?? '');
    _name = ControllerFieldPro()..setValue(widget.item?.name ?? '');
    _description = ControllerFieldPro()
      ..setValue(widget.item?.description ?? '');
    _parent = ControllerFieldDropdown<String>();
    if (widget.item?.parentId != null) {
      _parent.setDefaultValue(
        FormOption<String>(
          id: widget.item!.parentId!.hashCode,
          text: widget.item!.parentName ?? widget.item!.parentId!,
          value: widget.item!.parentId!,
        ),
      );
    } else {
      _parent.setDefaultValue(_noParent);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    _parent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FullWidgetGeneric(
      onDispose: () {},
      child: BlocBuilder<UnitsListCubit, UnitsListState>(
        builder: (context, state) {
          final parentItems = [
            _noParent,
            ...state.items
                .where((unit) => unit.id != widget.item?.id)
                .map(
                  (unit) => FormOption<String>(
                    id: unit.id.hashCode,
                    text: unit.name,
                    value: unit.id,
                  ),
                ),
          ];

          return AlertDialog(
            title: Text(_isEdit ? 'Editar unidad' : 'Nueva unidad'),
            content: SizedBox(
              width: 460,
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
                    AppDropdown<String>(
                      controller: _parent,
                      label: 'Unidad superior (opcional)',
                      items: parentItems,
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
    final parent = _parent.get();
    final success = await context.read<UnitsListCubit>().save(
          id: widget.item?.id,
          code: _code.getValue(),
          name: _name.getValue(),
          description: _description.getValue(),
          parentId: parent != null && parent.isNotEmpty ? parent : null,
        );
    if (success && mounted) Navigator.pop(context);
  }
}
