import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_context.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/features/administration/configuration/cubit/configuration_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => getIt<ConfigurationCubit>(),
      child: const ConfigurationView());
}

class ConfigurationView extends StatelessWidget {
  const ConfigurationView({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocListener<ConfigurationCubit, ConfigurationState>(
          listenWhen: (prev, next) => prev.generalStatus != next.generalStatus,
          listener: (context, state) {
            final message = state.dialogMessage;
            if (state.generalStatus == GeneralStatus.error) {
              context.showAppError(
                  title: message.title ?? 'Error', message: message.message);
            } else if (state.generalStatus == GeneralStatus.success &&
                message.title != null) {
              context.showAppSuccess(
                  title: message.title!, message: message.message);
            }
          },
          child: const ConfigurationBody());
}

class ConfigurationBody extends StatefulWidget {
  const ConfigurationBody({super.key});
  @override
  State<ConfigurationBody> createState() => _ConfigurationBodyState();
}

class _ConfigurationBodyState extends State<ConfigurationBody> {
  final _displayNameController = ControllerFieldPro();
  final _employeeController = ControllerFieldDropdown<AuthorityEmployee>();
  final _intakeController = ControllerFieldDropdown<String>();
  final _recipientController = ControllerFieldDropdown<AuthorityEmployee>();
  final _formKey = GlobalKey<FormState>();
  InstitutionalSettings? _appliedSettings;
  @override
  void dispose() {
    _displayNameController.dispose();
    _employeeController.dispose();
    _intakeController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = hasPermission(
        context.watch<AppSessionCubit>().state.userSession,
        Permissions.systemSettingsManage);
    return FullWidgetGeneric(
        onInit: () =>
            context.read<ConfigurationCubit>().load(canManage: canManage),
        child: AdminContent(
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              SectionHeader(
                  title: 'Configuración institucional',
                  actions: [
                    IconButton(
                        tooltip: 'Actualizar configuración',
                        onPressed: context
                                    .watch<ConfigurationCubit>()
                                    .state
                                    .generalStatus ==
                                GeneralStatus.loading
                            ? null
                            : () => context
                                .read<ConfigurationCubit>()
                                .load(canManage: canManage),
                        icon: const Icon(Icons.refresh))
                  ],
                  subtitle:
                      'Autoridad documental, Ventanilla y receptores iniciales'),
              const SizedBox(height: 20),
              BlocBuilder<ConfigurationCubit, ConfigurationState>(
                  builder: (context, state) {
                if (!state.loaded &&
                    state.generalStatus == GeneralStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.loaded && state.settings != _appliedSettings) {
                  _displayNameController
                      .setValue(state.settings.mayorDisplayName ?? '');
                  _appliedSettings = state.settings;
                }
                if (state.intakeUnitId.isNotEmpty) {
                  _intakeController.setValue(FormOption<String>(
                    id: state.intakeUnitId.hashCode,
                    value: state.intakeUnitId,
                    text: state.units
                            .where((x) => x.id == state.intakeUnitId)
                            .firstOrNull
                            ?.name ??
                        state.settings.intakeUnitName ??
                        state.intakeUnitId,
                  ));
                }
                final selected = state.selectedMayor;
                if (selected == null) {
                  _employeeController.clear();
                } else {
                  _employeeController.setValue(FormOption<AuthorityEmployee>(
                    id: selected.employeeId.hashCode,
                    value: selected,
                    text: selected.employeeName,
                    description:
                        '${selected.positionName} · ${selected.unitName}',
                  ));
                }
                return Card(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                            key: _formKey,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppDropdown<String>(
                                    controller: _intakeController,
                                    label: 'Unidad de Ventanilla',
                                    enabled: canManage &&
                                        state.loaded &&
                                        state.generalStatus !=
                                            GeneralStatus.loading,
                                    items: [
                                      for (final unit in state.units)
                                        FormOption<String>(
                                            id: unit.id.hashCode,
                                            value: unit.id,
                                            text: unit.name)
                                    ],
                                    onChanged: (option) => context
                                        .read<ConfigurationCubit>()
                                        .selectIntakeUnit(option.value!),
                                  ),
                                  const Text(
                                      'La unidad real del creador determina la política de Ventanilla.'),
                                  const SizedBox(height: 16),
                                  AppDropdown<AuthorityEmployee>(
                                    controller: _recipientController,
                                    label: 'Receptores iniciales de Alcaldía',
                                    searchHint: 'Buscar funcionario habilitado',
                                    enabled: canManage &&
                                        state.loaded &&
                                        state.generalStatus !=
                                            GeneralStatus.loading,
                                    items: [
                                      for (final employee in state.employees
                                          .where((x) => !state.recipientIds
                                              .contains(x.employeeId)))
                                        FormOption<AuthorityEmployee>(
                                            id: employee.employeeId.hashCode,
                                            value: employee,
                                            text: employee.employeeName,
                                            description:
                                                '${employee.positionName} · ${employee.unitName}',
                                            keywords: [
                                              employee.documentNumber ?? '',
                                              employee.positionName,
                                              employee.unitName
                                            ])
                                    ],
                                    onChanged: (option) {
                                      context
                                          .read<ConfigurationCubit>()
                                          .addRecipient(
                                              option.value!.employeeId);
                                      _recipientController.clear();
                                    },
                                  ),
                                  Wrap(spacing: 8, children: [
                                    for (final id in state.recipientIds)
                                      InputChip(
                                        label: Text([
                                              ...state.employees,
                                              ...state
                                                  .settings.initialRecipients
                                            ]
                                                .where(
                                                    (x) => x.employeeId == id)
                                                .firstOrNull
                                                ?.employeeName ??
                                            id),
                                        onDeleted: canManage &&
                                                state.generalStatus !=
                                                    GeneralStatus.loading
                                            ? () => context
                                                .read<ConfigurationCubit>()
                                                .removeRecipient(id)
                                            : null,
                                      )
                                  ]),
                                  const SizedBox(height: 20),
                                  AppDropdown<AuthorityEmployee>(
                                    controller: _employeeController,
                                    label: 'Máxima autoridad institucional',
                                    searchHint:
                                        'Buscar por nombre, CI, cargo o unidad',
                                    enabled: canManage &&
                                        state.loaded &&
                                        state.generalStatus !=
                                            GeneralStatus.loading,
                                    items: [
                                      for (final employee in state.employees)
                                        FormOption<AuthorityEmployee>(
                                          id: employee.employeeId.hashCode,
                                          value: employee,
                                          text: employee.employeeName,
                                          description:
                                              '${employee.positionName} · ${employee.unitName}',
                                          keywords: [
                                            employee.documentNumber ?? '',
                                            employee.positionName,
                                            employee.unitName
                                          ],
                                        )
                                    ],
                                    onChanged: (option) => context
                                        .read<ConfigurationCubit>()
                                        .selectMayor(option.value!),
                                  ),
                                  const Text(
                                      'La autoridad se usa en documentos. El receptor inicial seleccionado recibe el trámite.'),
                                  if (state.settings.mayorValidationError !=
                                      null)
                                    Text(state.settings.mayorValidationError!),
                                  const SizedBox(height: 20),
                                  AppTextField(
                                    controller: _displayNameController,
                                    label:
                                        'Texto de la Máxima Autoridad para documentos',
                                    maxLength: 200,
                                    readOnly: !canManage ||
                                        !state.loaded ||
                                        state.generalStatus ==
                                            GeneralStatus.loading,
                                  ),
                                  const Text(
                                      'Este texto es necesario para registrar nuevos documentos EDIE. Los documentos históricos conservan su texto original.'),
                                  const SizedBox(height: 20),
                                  if (canManage)
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: FilledButton.icon(
                                            onPressed: state.loaded &&
                                                    state.generalStatus !=
                                                        GeneralStatus.loading
                                                ? () {
                                                    if (!_formKey.currentState!
                                                        .validate()) return;
                                                    context
                                                        .read<
                                                            ConfigurationCubit>()
                                                        .save(
                                                            mayorDisplayName:
                                                                _displayNameController
                                                                    .getValue());
                                                  }
                                                : null,
                                            icon:
                                                const Icon(Icons.save_outlined),
                                            label: const Text('Guardar')))
                                  else
                                    const Text(
                                        'Solo lectura: no tiene permiso para modificar la configuración.'),
                                ]))));
              }),
            ]))));
  }
}
