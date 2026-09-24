import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/cubit/units_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/upsert_units/cubit/upsert_units_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/upsert_units/helpers/upsert_units_inherited.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpsertUnitsPage extends StatelessWidget {
  const UpsertUnitsPage({super.key, required this.typeOperation});

  final TypeOperation typeOperation;

  @override
  Widget build(BuildContext context) {
    return UpsertUnitsInherited(
      typeOperation: typeOperation,
      child: BlocProvider(
        create: (context) => getIt<UpsertUnitsCubit>(),
        child: const UpsertUnitsView(),
      ),
    );
  }
}

class UpsertUnitsView extends StatelessWidget {
  const UpsertUnitsView({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertUnitsInherited.of(context);
    final listCubit = context.read<UnitsCubit>();
    final upsertCubit = context.read<UpsertUnitsCubit>();
    final selected = listCubit.state.selected;

    return MultiBlocListener(
      listeners: [
        ListenerPro<UpsertUnitsCubit, UpsertUnitsState>().listen(
          onPressedSuccess: () => Navigator.of(context).pop(),
        ),
        ListenerPro<UpsertUnitsCubit, UpsertUnitsState>().event(
          onSuccess: (_) => listCubit.get(),
        ),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          if (inherited.typeOperation == TypeOperation.create) {
            inherited.clear();
            upsertCubit.init();
            return;
          }

          if (selected != null) {
            inherited.setData(selected);
            upsertCubit.init(editing: selected);
          }
        },
        onDispose: inherited.dispose,
        child: const UpsertUnitsBody(),
      ),
    );
  }
}

class UpsertUnitsBody extends StatelessWidget {
  const UpsertUnitsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertUnitsInherited.of(context);
    final isCreate = inherited.typeOperation == TypeOperation.create;
    final upsertCubit = context.read<UpsertUnitsCubit>();
    final listCubit = context.read<UnitsCubit>();
    final selected = listCubit.state.selected;

    return AlertDialog(
      title: Text(isCreate ? 'Nueva unidad' : 'Editar unidad'),
      content: SizedBox(
        width: 460,
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
              BlocBuilder<UpsertUnitsCubit, UpsertUnitsState>(
                builder: (context, state) {
                  if (!state.catalogLoaded) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  final parentItems = [
                    UpsertUnitsInherited.noParent,
                    ...upsertCubit
                        .parentOptions(excludeUnitId: selected?.id)
                        .map(
                          (unit) => FormOption<String>(
                            id: unit.id.hashCode,
                            text: unit.name,
                            value: unit.id,
                          ),
                        ),
                  ];

                  return AppDropdown<String>(
                    controller: inherited.parent,
                    label: 'Unidad superior (opcional)',
                    items: parentItems,
                  );
                },
              ),
              const SizedBox(height: 10),
              BlocBuilder<UpsertUnitsCubit, UpsertUnitsState>(
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
                          onPressed: isLoading || !state.catalogLoaded
                              ? null
                              : () {
                                  final validResult = inherited.valid();
                                  if (!validResult.isPassed) return;

                                  final parentValue = inherited.parent.get();
                                  final parentId = parentValue != null &&
                                          parentValue.isNotEmpty
                                      ? parentValue
                                      : null;

                                  if (isCreate) {
                                    upsertCubit.save(
                                      code: inherited.code.getValue(),
                                      name: inherited.name.getValue(),
                                      description:
                                          inherited.description.getValue(),
                                      parentId: parentId,
                                    );
                                  } else {
                                    if (selected == null) return;
                                    upsertCubit.update(
                                      entity: selected,
                                      name: inherited.name.getValue(),
                                      description:
                                          inherited.description.getValue(),
                                      parentId: parentId,
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
