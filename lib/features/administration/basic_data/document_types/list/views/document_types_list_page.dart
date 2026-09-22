import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list/cubit/document_types_list_cubit.dart';
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

class DocumentTypesListPage extends StatelessWidget {
  const DocumentTypesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DocumentTypesListCubit>()..init(),
      child: const DocumentTypesListView(),
    );
  }
}

class DocumentTypesListView extends StatelessWidget {
  const DocumentTypesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<DocumentTypesListCubit, DocumentTypesListState>().listen(),
      ],
      child: const DocumentTypesListBody(),
    );
  }
}

class DocumentTypesListBody extends StatelessWidget {
  const DocumentTypesListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    final canManage = hasPermission(session, Permissions.documentTypesManage);
    final cubit = context.read<DocumentTypesListCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Tipos de documento',
            subtitle: 'Catálogo institucional de tipos documentales',
            actions: [
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo tipo'),
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
            child: BlocBuilder<DocumentTypesListCubit, DocumentTypesListState>(
              builder: (context, state) {
                return AppDataGrid<DocumentTypeAdmin>(
                  items: state.items,
                  isLoading: state.listLoading ||
                      (state.items.isEmpty &&
                          state.generalStatus == GeneralStatus.loading),
                  emptyMessage: 'No se encontraron registros con ese criterio.',
                  columns: [
                    AppDataGridColumn<DocumentTypeAdmin>(
                      key: 'code',
                      label: 'Código',
                      width: 120,
                      value: (item) => item.code,
                      mobilePriority: 20,
                    ),
                    AppDataGridColumn<DocumentTypeAdmin>(
                      key: 'name',
                      label: 'Nombre',
                      value: (item) => item.name,
                      mobilePrimary: true,
                      mobilePriority: 1,
                    ),
                    AppDataGridColumn<DocumentTypeAdmin>(
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
                          AppDataGridAction<DocumentTypeAdmin>(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar',
                            onPressed: (item) =>
                                _showFormDialog(context, item: item),
                          ),
                          AppDataGridAction<DocumentTypeAdmin>(
                            icon: Icons.toggle_on_outlined,
                            tooltip: 'Desactivar',
                            visibleWhen: (item) => item.isActive,
                            onPressed: cubit.toggleActive,
                          ),
                          AppDataGridAction<DocumentTypeAdmin>(
                            icon: Icons.toggle_off_outlined,
                            tooltip: 'Activar',
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
    DocumentTypeAdmin? item,
  }) {
    final cubit = context.read<DocumentTypesListCubit>();
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _DocumentTypeFormDialog(item: item),
      ),
    );
  }
}

class _DocumentTypeFormDialog extends StatefulWidget {
  const _DocumentTypeFormDialog({this.item});

  final DocumentTypeAdmin? item;

  @override
  State<_DocumentTypeFormDialog> createState() =>
      _DocumentTypeFormDialogState();
}

class _DocumentTypeFormDialogState extends State<_DocumentTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final ControllerFieldPro _code;
  late final ControllerFieldPro _name;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    _code = ControllerFieldPro()..setValue(widget.item?.code ?? '');
    _name = ControllerFieldPro()..setValue(widget.item?.name ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FullWidgetGeneric(
      onDispose: () {},
      child: BlocBuilder<DocumentTypesListCubit, DocumentTypesListState>(
        builder: (context, state) {
          return AlertDialog(
            title: Text(_isEdit ? 'Editar tipo de documento' : 'Nuevo tipo de documento'),
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
                      validators: [
                        RequiredValid(error: 'Campo requerido'),
                      ],
                    ),
                    AppTextField(
                      controller: _name,
                      label: 'Nombre',
                      validators: [
                        RequiredValid(error: 'Campo requerido'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: state.saveInProgress
                    ? null
                    : () => Navigator.pop(context),
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
    final cubit = context.read<DocumentTypesListCubit>();
    final success = _isEdit
        ? await cubit.update(
            id: widget.item!.id,
            name: _name.getValue(),
          )
        : await cubit.create(
            code: _code.getValue(),
            name: _name.getValue(),
          );
    if (success && mounted) Navigator.pop(context);
  }
}
