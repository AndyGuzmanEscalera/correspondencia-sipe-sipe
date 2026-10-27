import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/administration/common/admin_upsert_bloc_listener.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/cubit/positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/helpers/upsert_positions_inherited.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/app_form_dialog.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpsertPositionsPage extends StatelessWidget {
  const UpsertPositionsPage({
    super.key,
    required this.typeOperation,
    this.hostDialogContext,
    this.ownerContext,
  });

  final TypeOperation typeOperation;
  final BuildContext? hostDialogContext;
  final BuildContext? ownerContext;

  @override
  Widget build(BuildContext context) {
    return UpsertPositionsInherited(
      typeOperation: typeOperation,
      child: BlocProvider(
        create: (context) => getIt<UpsertPositionsCubit>(),
        child: UpsertPositionsView(
          hostDialogContext: hostDialogContext,
          ownerContext: ownerContext,
        ),
      ),
    );
  }
}

class UpsertPositionsView extends StatelessWidget {
  const UpsertPositionsView({
    super.key,
    this.hostDialogContext,
    this.ownerContext,
  });

  final BuildContext? hostDialogContext;
  final BuildContext? ownerContext;

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertPositionsInherited.of(context);
    final listCubit = context.read<PositionsCubit>();

    return AdminUpsertBlocListener<UpsertPositionsCubit, UpsertPositionsState>(
      hostDialogContext: hostDialogContext,
      ownerContext: ownerContext,
      child: MultiBlocListener(
        listeners: [
          ListenerPro<UpsertPositionsCubit, UpsertPositionsState>().event(
            onSuccess: (_) => listCubit.get(),
          ),
        ],
        child: FullWidgetGeneric(
          onInit: () {
            context.read<UpsertPositionsCubit>().loadHierarchies();
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

    return BlocBuilder<UpsertPositionsCubit, UpsertPositionsState>(
      builder: (context, state) {
        final isLoading = state.generalStatus == GeneralStatus.loading;

        return AppFormDialog(
          title: isCreate ? 'Nuevo cargo' : 'Editar cargo',
          subtitle: isCreate
              ? 'Defina el código y nombre del cargo'
              : 'Modifique los datos del cargo',
          maxWidth: 480,
          isLoading: isLoading,
          isSubmitDisabled:
              state.hierarchiesLoading || state.hierarchiesError != null,
          submitLabel: isCreate ? 'Registrar' : 'Guardar',
          onSubmit: () {
            final validResult = inherited.valid();
            if (!validResult.isPassed) return;

            if (isCreate) {
              upsertCubit.save(
                code: inherited.code.getValue(),
                hierarchyId: inherited.hierarchyId.value,
                name: inherited.name.getValue(),
                description: inherited.description.getValue(),
                canViewUnitCorrespondence:
                    inherited.canViewUnitCorrespondence.value,
              );
            } else {
              final selected = listCubit.state.selected;
              if (selected == null) return;
              upsertCubit.update(
                entity: selected,
                hierarchyId: inherited.hierarchyId.value,
                hierarchyChanged: true,
                name: inherited.name.getValue(),
                description: inherited.description.getValue(),
                canViewUnitCorrespondence:
                    inherited.canViewUnitCorrespondence.value,
              );
            }
          },
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
                if (state.hierarchiesError != null)
                  Column(children: [
                    Text(state.hierarchiesError!),
                    TextButton(
                        onPressed: upsertCubit.loadHierarchies,
                        child: const Text('Reintentar jerarquías')),
                  ]),
                if (state.hierarchiesLoading) const LinearProgressIndicator(),
                ValueListenableBuilder<String?>(
                  valueListenable: inherited.hierarchyId,
                  builder: (context, selectedId, _) {
                    final choices =
                        state.hierarchies.where((h) => h.isActive).toList();
                    final legacy = selectedId != null &&
                        !choices.any((h) => h.id == selectedId);
                    return DropdownButtonFormField<String>(
                      key: const Key('position-hierarchy'),
                      value: selectedId ?? '',
                      decoration: const InputDecoration(
                          labelText: 'Jerarquía institucional'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                            value: '',
                            child: Text('Sin jerarquía (transición)')),
                        if (legacy)
                          DropdownMenuItem(
                              value: selectedId,
                              enabled: false,
                              child: Text(
                                  listCubit.state.selected?.hierarchyName ??
                                      'Jerarquía actual')),
                        ...choices.map((h) =>
                            DropdownMenuItem(value: h.id, child: Text(h.name))),
                      ],
                      onChanged: isLoading ||
                              state.hierarchiesLoading ||
                              state.hierarchiesError != null
                          ? null
                          : (id) => inherited.hierarchyId.value =
                              id == '' ? null : id,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: inherited.canViewUnitCorrespondence,
                  builder: (context, value, _) => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                        'Puede ver toda la correspondencia de su unidad'),
                    value: value,
                    onChanged: null,
                    subtitle: const Text(
                        'Campo legado conservado. El acceso de unidad se administra con correspondence.read.unit en Permisos del usuario.'),
                  ),
                ),
                AppTextField(
                  controller: inherited.description,
                  label: 'Descripción (opcional)',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
