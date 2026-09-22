import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_page.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list/cubit/correspondence_list_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list/helpers/create_correspondence_form_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondenceListPage extends StatelessWidget {
  const CorrespondenceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CorrespondenceListCubit>()..init(),
      child: const CorrespondenceListView(),
    );
  }
}

class CorrespondenceListView extends StatelessWidget {
  const CorrespondenceListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        ListenerPro<CorrespondenceListCubit, CorrespondenceListState>().listen(
          onPressedSuccess: () {
            context.read<SideMenuCubit>().refreshBadges();
          },
        ),
      ],
      child: const CorrespondenceListBody(),
    );
  }
}

class CorrespondenceListBody extends StatelessWidget {
  const CorrespondenceListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CorrespondenceListCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Correspondencias',
            subtitle: 'Registro institucional de trámites',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nueva correspondencia'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar por CITE, asunto o hoja de ruta',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          DataPanel(
            child: BlocBuilder<CorrespondenceListCubit, CorrespondenceListState>(
              builder: (context, state) {
                return AppDataGrid<CorrespondenceEntity>(
                  items: state.items,
                  isLoading: state.listLoading ||
                      (state.items.isEmpty &&
                          state.generalStatus == GeneralStatus.loading),
                  emptyMessage:
                      'No se encontraron trámites con ese criterio de búsqueda.',
                  onRowTap: (item) => _openDetail(context, item),
                  columns: [
                    AppDataGridColumn<CorrespondenceEntity>(
                      key: 'routeNumber',
                      label: 'HR',
                      width: 150,
                      value: (item) => item.routeNumber,
                      mobilePrimary: true,
                      mobilePriority: 1,
                    ),
                    AppDataGridColumn<CorrespondenceEntity>(
                      key: 'subject',
                      label: 'Asunto',
                      value: (item) => item.subject,
                      mobilePriority: 10,
                    ),
                    AppDataGridColumn<CorrespondenceEntity>(
                      key: 'type',
                      label: 'Tipo',
                      value: (item) => item.typeLabel,
                      mobilePriority: 30,
                      mobileVisible: false,
                    ),
                    AppDataGridColumn<CorrespondenceEntity>(
                      key: 'priority',
                      label: 'Prioridad',
                      value: (item) => item.priority,
                      mobilePriority: 25,
                    ),
                    AppDataGridColumn<CorrespondenceEntity>(
                      key: 'status',
                      label: 'Estado',
                      type: AppDataGridCellType.status,
                      width: 130,
                      value: (item) => item.statusLabel,
                      mobilePriority: 5,
                      cellBuilder: (context, item, value) =>
                          StatusBadge(label: value?.toString() ?? '-'),
                    ),
                    AppDataGridColumn<CorrespondenceEntity>(
                      key: 'responsible',
                      label: 'Responsable',
                      value: (item) => item.currentResponsibleLabel,
                      mobilePriority: 20,
                    ),
                    AppDataGridColumn<CorrespondenceEntity>(
                      key: 'registeredAt',
                      label: 'Fecha',
                      type: AppDataGridCellType.date,
                      width: 120,
                      value: (item) => item.registeredAt,
                      mobilePriority: 15,
                    ),
                  ],
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

  void _openDetail(BuildContext context, CorrespondenceEntity item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CorrespondenceDetailPage(correspondenceId: item.id),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) {
    final cubit = context.read<CorrespondenceListCubit>();
    cubit.resetCreateDestinationUsers();
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _CreateCorrespondenceDialog(),
      ),
    );
  }
}

class _CreateCorrespondenceDialog extends StatefulWidget {
  const _CreateCorrespondenceDialog();

  @override
  State<_CreateCorrespondenceDialog> createState() =>
      _CreateCorrespondenceDialogState();
}

class _CreateCorrespondenceDialogState extends State<_CreateCorrespondenceDialog> {
  static const _typeItems = [
    FormOption<CorrespondenceTypeCode>(
      id: 1,
      text: 'Externa (CE)',
      value: CorrespondenceTypeCode.ce,
    ),
    FormOption<CorrespondenceTypeCode>(
      id: 2,
      text: 'Interna (CI)',
      value: CorrespondenceTypeCode.ci,
    ),
  ];

  static const _priorityItems = [
    FormOption<String>(id: 1, text: 'Alta', value: 'Alta'),
    FormOption<String>(id: 2, text: 'Media', value: 'Media'),
    FormOption<String>(id: 3, text: 'Baja', value: 'Baja'),
  ];

  static const _noUserOption = FormOption<String>(
    id: 0,
    text: 'Sin usuario específico',
    value: '',
  );

  CorrespondenceTypeCode _selectedType = CorrespondenceTypeCode.ce;

  bool get _isExternal => _selectedType == CorrespondenceTypeCode.ce;

  @override
  Widget build(BuildContext context) {
    return CreateCorrespondenceFormInherited(
      child: Builder(
        builder: (dialogContext) {
          final inherited = CreateCorrespondenceFormInherited.of(dialogContext);

          return BlocBuilder<CorrespondenceListCubit, CorrespondenceListState>(
            builder: (context, state) {
              final docTypeItems = state.documentTypes
                  .map(
                    (item) => FormOption<String>(
                      id: item.id.hashCode,
                      text: item.name,
                      value: item.id,
                    ),
                  )
                  .toList();

              final unitItems = state.organizationalUnits
                  .map(
                    (unit) => FormOption<String>(
                      id: unit.id.hashCode,
                      text: unit.name,
                      value: unit.id,
                    ),
                  )
                  .toList();

              final userItems = [
                _noUserOption,
                ...state.createUnitUsers.map(
                  (user) => FormOption<String>(
                    id: user.id.hashCode,
                    text: user.displayName,
                    value: user.id,
                  ),
                ),
              ];

              final catalogsReady = state.createCatalogsReady;
              final canSubmit = catalogsReady &&
                  !state.createInProgress &&
                  !state.unitUsersLoading;

              return FullWidgetGeneric(
                onDispose: inherited.dispose,
                child: AlertDialog(
                  title: const Text('Nueva correspondencia'),
                  content: SizedBox(
                    width: 480,
                    child: SingleChildScrollView(
                      child: Form(
                        key: inherited.formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!catalogsReady && state.catalogsLoading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: LinearProgressIndicator(),
                              ),
                            if (!catalogsReady && !state.catalogsLoading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'No se pudieron cargar los catálogos necesarios.',
                                ),
                              ),
                            AppTextField(
                              controller: inherited.subject,
                              label: 'Asunto',
                              validators: [
                                RequiredValid(error: 'Campo requerido'),
                              ],
                            ),
                            AppTextField(
                              controller: inherited.reference,
                              label: 'Referencia (opcional)',
                            ),
                            if (docTypeItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No hay tipos de documento disponibles.',
                                ),
                              )
                            else
                              AppDropdown<String>(
                                controller: inherited.documentType,
                                label: 'Tipo de documento',
                                items: docTypeItems,
                                validators: [
                                  RequiredValid(
                                    error: 'Seleccione un tipo de documento',
                                  ),
                                ],
                              ),
                            AppDropdown<CorrespondenceTypeCode>(
                              controller: inherited.type,
                              label: 'Tipo de correspondencia',
                              items: _typeItems,
                              onChanged: (option) {
                                setState(() {
                                  _selectedType = option.value!;
                                });
                              },
                            ),
                            AppDropdown<String>(
                              controller: inherited.priority,
                              label: 'Prioridad',
                              items: _priorityItems,
                              validators: [
                                RequiredValid(error: 'Seleccione una prioridad'),
                              ],
                            ),
                            if (unitItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No hay unidades organizacionales activas.',
                                ),
                              )
                            else
                              AppDropdown<String>(
                                controller: inherited.toUnit,
                                label: 'Unidad destino',
                                items: unitItems,
                                validators: [
                                  RequiredValid(
                                    error: 'Seleccione una unidad destino',
                                  ),
                                ],
                                onChanged: (option) {
                                  inherited.toUser.clear();
                                  context
                                      .read<CorrespondenceListCubit>()
                                      .loadCreateUnitUsers(option.value!);
                                },
                              ),
                            if (inherited.toUnit.isExist()) ...[
                              if (state.unitUsersLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: LinearProgressIndicator(),
                                ),
                              AppDropdown<String>(
                                controller: inherited.toUser,
                                label: 'Usuario destino (opcional)',
                                items: userItems,
                                onChanged: (_) {},
                              ),
                            ],
                            AppTextField(
                              controller: inherited.initialInstruction,
                              label: 'Instrucción inicial / proveído (opcional)',
                            ),
                            if (_isExternal) ...[
                              AppTextField(
                                controller: inherited.senderName,
                                label: 'Remitente externo',
                                validators: [
                                  RequiredValid(error: 'Campo requerido'),
                                ],
                              ),
                              AppTextField(
                                controller: inherited.senderDocument,
                                label: 'Documento del remitente (opcional)',
                              ),
                              AppTextField(
                                controller: inherited.senderContact,
                                label: 'Contacto del remitente (opcional)',
                                inputType: TextInputType.phone,
                              ),
                              AppTextField(
                                controller: inherited.originDescription,
                                label: 'Descripción del origen (opcional)',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: state.createInProgress
                          ? null
                          : () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: canSubmit
                          ? () => _submit(dialogContext, inherited)
                          : null,
                      child: state.createInProgress
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Registrar'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    CreateCorrespondenceFormInherited inherited,
  ) async {
    if (!inherited.formKey.validateForm()) return;

    final type = inherited.type.get();
    final priority = inherited.priority.get();
    final documentTypeId = inherited.documentType.get();
    final toUnitId = inherited.toUnit.get();
    if (type == null ||
        priority == null ||
        documentTypeId == null ||
        toUnitId == null ||
        toUnitId.isEmpty) {
      return;
    }

    final selectedUser =
        inherited.toUser.isExist() ? inherited.toUser.get() : null;

    final success = await context.read<CorrespondenceListCubit>().create(
          CreateCorrespondenceFormData(
            subject: inherited.subject.getValue(),
            reference: inherited.reference.getValue(),
            type: type,
            priorityLabel: priority,
            documentTypeId: documentTypeId,
            initialToUnitId: toUnitId,
            initialToUserId: selectedUser != null && selectedUser.isNotEmpty
                ? selectedUser
                : null,
            initialInstruction: inherited.initialInstruction.getValue(),
            senderName: inherited.senderName.getValue(),
            senderDocument: inherited.senderDocument.getValue(),
            senderContact: inherited.senderContact.getValue(),
            originDescription: inherited.originDescription.getValue(),
          ),
        );

    if (success && context.mounted) {
      Navigator.pop(context);
    }
  }
}
