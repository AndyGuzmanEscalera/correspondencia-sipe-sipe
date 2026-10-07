import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_context.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/features/administration/configuration/cubit/configuration_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
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
  final _controller = ControllerFieldDropdown<AuthorityEmployee>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  FormOption<AuthorityEmployee> _option(AuthorityEmployee employee, int id) =>
      FormOption(
          id: id,
          value: employee,
          text: employee.employeeName,
          description: '${employee.positionName} · ${employee.unitName}',
          keywords: [
            employee.documentNumber ?? '',
            employee.positionName,
            employee.unitName
          ]);

  @override
  Widget build(BuildContext context) {
    final canManage = hasPermission(
        context.watch<AppSessionCubit>().state.userSession,
        Permissions.systemSettingsManage);
    return FullWidgetGeneric(
        onInit: () =>
            context.read<ConfigurationCubit>().load(canManage: canManage),
        child: AdminContent(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const SectionHeader(
                  title: 'Configuración institucional',
                  subtitle:
                      'Autoridad institucional para el primer destinatario automático EDIE'),
              const SizedBox(height: 20),
              BlocBuilder<ConfigurationCubit, ConfigurationState>(
                  builder: (context, state) {
                if (!state.loaded &&
                    state.generalStatus == GeneralStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final selected = state.selectedMayor;
                if (selected == null) {
                  _controller.clear();
                } else {
                  final index = state.employees.indexWhere(
                      (item) => item.employeeId == selected.employeeId);
                  _controller
                      .setValue(_option(selected, index < 0 ? -1 : index + 1));
                }
                return Card(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppDropdown<AuthorityEmployee>(
                                  controller: _controller,
                                  enabled: canManage &&
                                      state.loaded &&
                                      state.generalStatus !=
                                          GeneralStatus.loading,
                                  label: 'Alcalde / Máxima Autoridad Ejecutiva',
                                  searchHint:
                                      'Buscar por nombre, CI, cargo o unidad',
                                  items: [
                                    for (var i = 0;
                                        i < state.employees.length;
                                        i++)
                                      _option(state.employees[i], i + 1)
                                  ],
                                  onChanged: (option) => context
                                      .read<ConfigurationCubit>()
                                      .selectMayor(option.value!)),
                              if (selected != null)
                                Text(
                                    '${selected.positionName} · ${selected.unitName}'),
                              if (state.settings.mayorValidationError != null)
                                Text(state.settings.mayorValidationError!),
                              if (selected == null)
                                const Text(
                                    'Debe configurar al Alcalde/Máxima Autoridad Ejecutiva antes de registrar documentos EDIE.'),
                              if (canManage)
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.icon(
                                        onPressed: state.loaded &&
                                                state.generalStatus !=
                                                    GeneralStatus.loading
                                            ? () => context
                                                .read<ConfigurationCubit>()
                                                .save()
                                            : null,
                                        icon: const Icon(Icons.save_outlined),
                                        label: const Text('Guardar')))
                              else
                                const Text(
                                    'Solo lectura: no tiene permiso para modificar la configuración.'),
                            ])));
              }),
            ])));
  }
}
