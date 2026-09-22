import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list/cubit/employees_list_cubit.dart';
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

class EmployeesListPage extends StatelessWidget {
  const EmployeesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmployeesListCubit>()..init(),
      child: const EmployeesListView(),
    );
  }
}

class EmployeesListView extends StatelessWidget {
  const EmployeesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<EmployeesListCubit, EmployeesListState>().listen(),
      ],
      child: const EmployeesListBody(),
    );
  }
}

class EmployeesListBody extends StatelessWidget {
  const EmployeesListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    final canManage = hasPermission(session, Permissions.employeesManage);
    final cubit = context.read<EmployeesListCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Funcionarios',
            subtitle: 'Personal institucional vinculado al sistema',
            actions: [
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo funcionario'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar funcionario, cargo o unidad',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          DataPanel(
            child: BlocBuilder<EmployeesListCubit, EmployeesListState>(
              builder: (context, state) {
                return AppDataGrid<EmployeeAdmin>(
                  items: state.items,
                  isLoading: state.listLoading ||
                      (state.items.isEmpty &&
                          state.generalStatus == GeneralStatus.loading),
                  emptyMessage: 'No se encontraron registros con ese criterio.',
                  columns: [
                    AppDataGridColumn<EmployeeAdmin>(
                      key: 'name',
                      label: 'Funcionario',
                      value: (item) => item.fullName,
                      mobilePrimary: true,
                      mobilePriority: 1,
                    ),
                    AppDataGridColumn<EmployeeAdmin>(
                      key: 'document',
                      label: 'CI',
                      width: 130,
                      value: (item) => item.documentNumber,
                      mobilePriority: 10,
                    ),
                    AppDataGridColumn<EmployeeAdmin>(
                      key: 'unit',
                      label: 'Unidad',
                      value: (item) => item.unitName,
                      mobilePriority: 15,
                    ),
                    AppDataGridColumn<EmployeeAdmin>(
                      key: 'position',
                      label: 'Cargo',
                      value: (item) => item.positionName,
                      mobilePriority: 20,
                    ),
                    AppDataGridColumn<EmployeeAdmin>(
                      key: 'email',
                      label: 'Correo',
                      value: (item) => item.email,
                      mobileVisible: false,
                    ),
                    AppDataGridColumn<EmployeeAdmin>(
                      key: 'phone',
                      label: 'Teléfono',
                      value: (item) => item.phone,
                      mobileVisible: false,
                    ),
                    AppDataGridColumn<EmployeeAdmin>(
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
                          AppDataGridAction<EmployeeAdmin>(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar',
                            onPressed: (item) =>
                                _showFormDialog(context, item: item),
                          ),
                          AppDataGridAction<EmployeeAdmin>(
                            icon: Icons.toggle_on_outlined,
                            tooltip: 'Activar/desactivar',
                            visibleWhen: (item) => item.isActive,
                            onPressed: cubit.toggleActive,
                          ),
                          AppDataGridAction<EmployeeAdmin>(
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

  Future<void> _showFormDialog(BuildContext context, {EmployeeAdmin? item}) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<EmployeesListCubit>(),
        child: _EmployeeFormDialog(item: item),
      ),
    );
  }
}

class _EmployeeFormDialog extends StatefulWidget {
  const _EmployeeFormDialog({this.item});
  final EmployeeAdmin? item;

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final ControllerFieldPro _firstName;
  late final ControllerFieldPro _lastName;
  late final ControllerFieldPro _document;
  late final ControllerFieldPro _email;
  late final ControllerFieldPro _phone;
  late final ControllerFieldDropdown<String> _unit;
  late final ControllerFieldDropdown<String> _position;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    _firstName = ControllerFieldPro()..setValue(widget.item?.firstName ?? '');
    _lastName = ControllerFieldPro()..setValue(widget.item?.lastName ?? '');
    _document = ControllerFieldPro()
      ..setValue(widget.item?.documentNumber ?? '');
    _email = ControllerFieldPro()..setValue(widget.item?.email ?? '');
    _phone = ControllerFieldPro()..setValue(widget.item?.phone ?? '');
    _unit = ControllerFieldDropdown<String>();
    _position = ControllerFieldDropdown<String>();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _document.dispose();
    _email.dispose();
    _phone.dispose();
    _unit.dispose();
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FullWidgetGeneric(
      onDispose: () {},
      child: BlocBuilder<EmployeesListCubit, EmployeesListState>(
        builder: (context, state) {
          if (!state.catalogsReady) {
            return AlertDialog(
              title: Text(_isEdit ? 'Editar funcionario' : 'Nuevo funcionario'),
              content: state.catalogsLoading
                  ? const LinearProgressIndicator()
                  : const Text(
                      'No se pudieron cargar unidades y cargos activos.',
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          }

          final unitItems = state.units
              .map(
                (unit) => FormOption<String>(
                  id: unit.id.hashCode,
                  text: unit.name,
                  value: unit.id,
                ),
              )
              .toList();
          final positionItems = state.positions
              .map(
                (position) => FormOption<String>(
                  id: position.id.hashCode,
                  text: position.name,
                  value: position.id,
                ),
              )
              .toList();

          if (widget.item?.unitId != null && !_unit.isExist()) {
            _unit.setDefaultValue(
              FormOption<String>(
                id: widget.item!.unitId!.hashCode,
                text: widget.item!.unitName ?? widget.item!.unitId!,
                value: widget.item!.unitId!,
              ),
            );
          }
          if (widget.item?.positionId != null && !_position.isExist()) {
            _position.setDefaultValue(
              FormOption<String>(
                id: widget.item!.positionId!.hashCode,
                text: widget.item!.positionName ?? widget.item!.positionId!,
                value: widget.item!.positionId!,
              ),
            );
          }

          return AlertDialog(
            title: Text(_isEdit ? 'Editar funcionario' : 'Nuevo funcionario'),
            content: SizedBox(
              width: 480,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FormSaveError(message: state.saveError),
                      AppTextField(
                        controller: _firstName,
                        label: 'Nombres',
                        validators: [RequiredValid(error: 'Campo requerido')],
                      ),
                      AppTextField(
                        controller: _lastName,
                        label: 'Apellidos',
                        validators: [RequiredValid(error: 'Campo requerido')],
                      ),
                      AppTextField(
                        controller: _document,
                        label: 'Documento de identidad',
                        validators: [RequiredValid(error: 'Campo requerido')],
                      ),
                      AppTextField(
                        controller: _email,
                        label: 'Correo (opcional)',
                        inputType: TextInputType.emailAddress,
                      ),
                      AppTextField(
                        controller: _phone,
                        label: 'Teléfono (opcional)',
                        inputType: TextInputType.phone,
                      ),
                      AppDropdown<String>(
                        controller: _unit,
                        label: 'Unidad',
                        items: unitItems,
                        validators: [RequiredValid(error: 'Seleccione una unidad')],
                      ),
                      AppDropdown<String>(
                        controller: _position,
                        label: 'Cargo',
                        items: positionItems,
                        validators: [RequiredValid(error: 'Seleccione un cargo')],
                      ),
                    ],
                  ),
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
    final unitId = _unit.get();
    final positionId = _position.get();
    if (unitId == null || positionId == null) return;

    final success = await context.read<EmployeesListCubit>().save(
          id: widget.item?.id,
          firstName: _firstName.getValue(),
          lastName: _lastName.getValue(),
          documentNumber: _document.getValue(),
          unitId: unitId,
          positionId: positionId,
          email: _email.getValue(),
          phone: _phone.getValue(),
        );
    if (success && mounted) Navigator.pop(context);
  }
}
