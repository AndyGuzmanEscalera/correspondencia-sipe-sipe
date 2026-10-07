import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_context.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/features/administration/configuration/cubit/configuration_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ConfigurationCubit>(),
      child: const ConfigurationView(),
    );
  }
}

class ConfigurationView extends StatelessWidget {
  const ConfigurationView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigurationCubit, ConfigurationState>(
      listenWhen: (prev, next) => prev.generalStatus != next.generalStatus,
      listener: (context, state) {
        final message = state.dialogMessage;
        switch (state.generalStatus) {
          case GeneralStatus.loading:
            if (message.message.isNotEmpty) {
              // loading feedback via dialog message on save
            }
          case GeneralStatus.error:
            context.showAppError(
              title: message.title ?? 'Error',
              message: message.message,
            );
          case GeneralStatus.success:
            if (message.title != null && message.message.isNotEmpty) {
              context.showAppSuccess(
                title: message.title!,
                message: message.message,
              );
            }
          case GeneralStatus.initial:
            break;
        }
      },
      child: const ConfigurationBody(),
    );
  }
}

class ConfigurationBody extends StatefulWidget {
  const ConfigurationBody({super.key});

  @override
  State<ConfigurationBody> createState() => _ConfigurationBodyState();
}

class _ConfigurationBodyState extends State<ConfigurationBody> {
  final _formKey = GlobalKey<FormState>();
  late final ControllerFieldPro _mayorNameController;

  @override
  void initState() {
    super.initState();
    _mayorNameController = ControllerFieldPro();
  }

  @override
  void dispose() {
    _mayorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = hasPermission(
      context.watch<AppSessionCubit>().state.userSession,
      Permissions.systemSettingsManage,
    );

    return FullWidgetGeneric(
      onInit: () => context.read<ConfigurationCubit>().load(),
      child: BlocListener<ConfigurationCubit, ConfigurationState>(
        listenWhen: (prev, next) =>
            next.loaded && (!prev.loaded || prev.mayorDisplayName != next.mayorDisplayName),
        listener: (context, state) {
          _mayorNameController.setValue(state.mayorDisplayName);
        },
        child: AdminContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Configuración institucional',
                subtitle:
                    'Parámetros visibles en encadenamiento y documentos oficiales',
              ),
              const SizedBox(height: 20),
              BlocBuilder<ConfigurationCubit, ConfigurationState>(
                builder: (context, state) {
                  if (state.generalStatus == GeneralStatus.loading &&
                      !state.loaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: UiColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Titular ejecutivo (Alcalde/Alcaldesa)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Nombre que aparece en PARA y en el primer destinatario '
                              'del PDF de encadenamiento. Si lo deja vacío, se usará el '
                              'nombre del funcionario con cargo ALCALDE/ALCALDESA.',
                              style: TextStyle(
                                color: UiColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _mayorNameController,
                              label: 'Nombre del alcalde/alcaldesa',
                              readOnly: !canManage,
                              maxLength: 200,
                            ),
                            if (canManage) ...[
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed:
                                      (!state.loaded || state.generalStatus == GeneralStatus.loading)
                                          ? null
                                          : () {
                                              if (!_formKey.currentState!
                                                  .validate()) {
                                                return;
                                              }
                                              context
                                                  .read<ConfigurationCubit>()
                                                  .save(_mayorNameController.getValue());
                                            },
                                  icon: const Icon(Icons.save_outlined),
                                  label: const Text('Guardar'),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Solo lectura: no tiene permiso para modificar '
                                'la configuración.',
                                style: TextStyle(
                                  color: UiColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
