import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/cubit/positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/helpers/upsert_positions_inherited.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpsertPositionsPage extends StatelessWidget {
  const UpsertPositionsPage({super.key, required this.typeOperation});

  final TypeOperation typeOperation;

  @override
  Widget build(BuildContext context) {
    return UpsertPositionsInherited(
      typeOperation: typeOperation,
      child: BlocProvider(
        create: (context) => getIt<UpsertPositionsCubit>(),
        child: const UpsertPositionsView(),
      ),
    );
  }
}

class UpsertPositionsView extends StatelessWidget {
  const UpsertPositionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertPositionsInherited.of(context);
    final listCubit = context.read<PositionsCubit>();

    return MultiBlocListener(
      listeners: [
        ListenerPro<UpsertPositionsCubit, UpsertPositionsState>().listen(
          onPressedSuccess: () => Navigator.of(context).pop(),
        ),
        ListenerPro<UpsertPositionsCubit, UpsertPositionsState>().event(
          onSuccess: (_) => listCubit.get(),
        ),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          if (inherited.typeOperation == TypeOperation.create) {
            inherited.clear();
            return;
          }

          final selected = listCubit.state.selected;
          if (selected != null) {
            inherited.setData(selected);
          }
        },
        onDispose: inherited.dispose,
        child: const UpsertPositionsBody(),
      ),
    );
  }
}

class UpsertPositionsBody extends StatelessWidget {
  const UpsertPositionsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertPositionsInherited.of(context);
    final isCreate = inherited.typeOperation == TypeOperation.create;
    final upsertCubit = context.read<UpsertPositionsCubit>();
    final listCubit = context.read<PositionsCubit>();

    return AlertDialog(
      title: Text(isCreate ? 'Nuevo cargo' : 'Editar cargo'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: inherited.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: inherited.code,
                label: 'Código',
                readOnly: !isCreate,
                validators: [
                  RequiredValid(error: 'Campo requerido'),
                ],
              ),
              AppTextField(
                controller: inherited.name,
                label: 'Nombre',
                validators: [
                  RequiredValid(error: 'Campo requerido'),
                ],
              ),
              AppTextField(
                controller: inherited.description,
                label: 'Descripción (opcional)',
              ),
              const SizedBox(height: 10),
              BlocBuilder<UpsertPositionsCubit, UpsertPositionsState>(
                builder: (context, state) {
                  final isLoading =
                      state.generalStatus == GeneralStatus.loading;

                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  final validResult = inherited.valid();
                                  if (!validResult.isPassed) return;

                                  if (isCreate) {
                                    upsertCubit.save(
                                      code: inherited.code.getValue(),
                                      name: inherited.name.getValue(),
                                      description:
                                          inherited.description.getValue(),
                                    );
                                  } else {
                                    final selected = listCubit.state.selected;
                                    if (selected == null) return;
                                    upsertCubit.update(
                                      entity: selected,
                                      name: inherited.name.getValue(),
                                      description:
                                          inherited.description.getValue(),
                                    );
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(isCreate ? 'Registrar' : 'Guardar'),
                        ),
                      ),
                    ],
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
