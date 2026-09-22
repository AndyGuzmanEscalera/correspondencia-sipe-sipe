import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list/cubit/users_list_cubit.dart';
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
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_password.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersListPage extends StatelessWidget {
  const UsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UsersListCubit>()..init(),
      child: const UsersListView(),
    );
  }
}

class UsersListView extends StatelessWidget {
  const UsersListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<UsersListCubit, UsersListState>().listen(),
      ],
      child: const UsersListBody(),
    );
  }
}

class UsersListBody extends StatelessWidget {
  const UsersListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    final canManage = hasPermission(session, Permissions.usersManage);
    final cubit = context.read<UsersListCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Usuarios',
            subtitle: 'Cuentas de acceso al sistema',
            actions: [
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo usuario'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar por usuario, funcionario o unidad',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          DataPanel(
            child: BlocBuilder<UsersListCubit, UsersListState>(
              builder: (context, state) {
                return AppDataGrid<UserAdmin>(
                  items: state.items,
                  isLoading: state.listLoading ||
                      (state.items.isEmpty &&
                          state.generalStatus == GeneralStatus.loading),
                  emptyMessage: 'No se encontraron registros con ese criterio.',
                  columns: [
                    AppDataGridColumn<UserAdmin>(
                      key: 'username',
                      label: 'Usuario',
                      value: (item) => item.username,
                      mobilePrimary: true,
                      mobilePriority: 1,
                    ),
                    AppDataGridColumn<UserAdmin>(
                      key: 'employee',
                      label: 'Funcionario',
                      value: (item) => item.employeeName,
                      mobilePriority: 10,
                    ),
                    AppDataGridColumn<UserAdmin>(
                      key: 'unit',
                      label: 'Unidad',
                      value: (item) => item.unitName,
                      mobilePriority: 15,
                    ),
                    AppDataGridColumn<UserAdmin>(
                      key: 'roles',
                      label: 'Roles',
                      value: (item) => item.roleCodes.join(', '),
                      mobilePriority: 25,
                    ),
                    AppDataGridColumn<UserAdmin>(
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
                          AppDataGridAction<UserAdmin>(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar',
                            onPressed: (item) =>
                                _showFormDialog(context, item: item),
                          ),
                          AppDataGridAction<UserAdmin>(
                            icon: Icons.toggle_on_outlined,
                            tooltip: 'Activar/desactivar',
                            visibleWhen: (item) => item.isActive,
                            onPressed: cubit.toggleActive,
                          ),
                          AppDataGridAction<UserAdmin>(
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

  Future<void> _showFormDialog(BuildContext context, {UserAdmin? item}) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<UsersListCubit>(),
        child: _UserFormDialog(item: item),
      ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({this.item});
  final UserAdmin? item;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final ControllerFieldPro _username;
  late final ControllerFieldPro _email;
  late final ControllerFieldPro _password;
  late final ControllerFieldDropdown<String> _employee;
  late final ControllerFieldDropdown<String> _role;
  final Set<String> _selectedRoleIds = {};

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    _username = ControllerFieldPro()..setValue(widget.item?.username ?? '');
    _email = ControllerFieldPro()..setValue(widget.item?.email ?? '');
    _password = ControllerFieldPro();
    _employee = ControllerFieldDropdown<String>();
    _role = ControllerFieldDropdown<String>();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _employee.dispose();
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FullWidgetGeneric(
      onDispose: () {},
      child: BlocBuilder<UsersListCubit, UsersListState>(
        builder: (context, state) {
          if (!state.catalogsReady) {
            return AlertDialog(
              title: Text(_isEdit ? 'Editar usuario' : 'Nuevo usuario'),
              content: state.catalogsLoading
                  ? const LinearProgressIndicator()
                  : const Text(
                      'No se pudieron cargar funcionarios y roles activos.',
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          }

          final employeeItems = state.employees
              .map(
                (employee) => FormOption<String>(
                  id: employee.id.hashCode,
                  text: employee.fullName,
                  value: employee.id,
                ),
              )
              .toList();
          final roleItems = state.roles
              .map(
                (role) => FormOption<String>(
                  id: role.id.hashCode,
                  text: role.name,
                  value: role.id,
                ),
              )
              .toList();

          if (widget.item?.employeeId != null && !_employee.isExist()) {
            _employee.setDefaultValue(
              FormOption<String>(
                id: widget.item!.employeeId!.hashCode,
                text: widget.item!.employeeName ?? widget.item!.employeeId!,
                value: widget.item!.employeeId!,
              ),
            );
          }

          if (_isEdit && _selectedRoleIds.isEmpty) {
            for (final code in widget.item!.roleCodes) {
              final role = state.roles.firstWhere(
                (item) => item.code == code,
                orElse: () => const RoleOption(id: '', code: '', name: ''),
              );
              if (role.id.isNotEmpty) _selectedRoleIds.add(role.id);
            }
          }

          return AlertDialog(
            title: Text(_isEdit ? 'Editar usuario' : 'Nuevo usuario'),
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
                        controller: _username,
                        label: 'Nombre de usuario',
                        validators: [RequiredValid(error: 'Campo requerido')],
                      ),
                      AppTextField(
                        controller: _email,
                        label: 'Correo (opcional)',
                        inputType: TextInputType.emailAddress,
                      ),
                      if (!_isEdit)
                        AppTextPassword(
                          controller: _password,
                          label: 'Contraseña inicial',
                          validators: [RequiredValid(error: 'Campo requerido')],
                        ),
                      AppDropdown<String>(
                        controller: _employee,
                        label: 'Funcionario',
                        items: employeeItems,
                        validators: [
                          RequiredValid(error: 'Seleccione un funcionario'),
                        ],
                      ),
                      AppDropdown<String>(
                        controller: _role,
                        label: 'Agregar rol',
                        items: roleItems,
                        onChanged: (option) {
                          setState(() {
                            _selectedRoleIds.add(option.value!);
                            _role.clear();
                          });
                        },
                      ),
                      if (_selectedRoleIds.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: _selectedRoleIds.map((roleId) {
                            final role = state.roles.firstWhere(
                              (item) => item.id == roleId,
                            );
                            return Chip(
                              label: Text(role.name),
                              onDeleted: () {
                                setState(() => _selectedRoleIds.remove(roleId));
                              },
                            );
                          }).toList(),
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
    if (_selectedRoleIds.isEmpty) return;

    final employeeId = _employee.get();
    if (employeeId == null) return;

    final cubit = context.read<UsersListCubit>();
    final success = _isEdit
        ? await cubit.update(
            id: widget.item!.id,
            username: _username.getValue(),
            employeeId: employeeId,
            roleIds: _selectedRoleIds.toList(),
            email: _email.getValue(),
          )
        : await cubit.create(
            username: _username.getValue(),
            employeeId: employeeId,
            initialPassword: _password.getValue(),
            roleIds: _selectedRoleIds.toList(),
            email: _email.getValue(),
          );
    if (success && mounted) Navigator.pop(context);
  }
}
