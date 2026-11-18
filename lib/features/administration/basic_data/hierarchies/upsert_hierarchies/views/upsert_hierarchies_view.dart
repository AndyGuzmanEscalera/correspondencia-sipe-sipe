import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/administration/common/admin_upsert_bloc_listener.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/cubit/hierarchies_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/upsert_hierarchies/cubit/upsert_hierarchies_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/upsert_hierarchies/helpers/upsert_hierarchies_inherited.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/app_form_dialog.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpsertHierarchiesPage extends StatelessWidget {
  const UpsertHierarchiesPage({
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
    return UpsertHierarchiesInherited(
      typeOperation: typeOperation,
      child: BlocProvider(
        create: (context) => getIt<UpsertHierarchiesCubit>(),
        child: UpsertHierarchiesView(
          hostDialogContext: hostDialogContext,
          ownerContext: ownerContext,
        ),
      ),
    );
  }
}

class UpsertHierarchiesView extends StatelessWidget {
  const UpsertHierarchiesView({
    super.key,
    this.hostDialogContext,
    this.ownerContext,
  });

  final BuildContext? hostDialogContext;
  final BuildContext? ownerContext;

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertHierarchiesInherited.of(context);
    final listCubit = context.read<HierarchiesCubit>();

    return AdminUpsertBlocListener<UpsertHierarchiesCubit,
        UpsertHierarchiesState>(
      hostDialogContext: hostDialogContext,
      ownerContext: ownerContext,
      child: MultiBlocListener(
        listeners: [
          ListenerPro<UpsertHierarchiesCubit, UpsertHierarchiesState>().event(
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
          child: const UpsertHierarchiesBody(),
        ),
      ),
    );
  }
}

class UpsertHierarchiesBody extends StatelessWidget {
  const UpsertHierarchiesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertHierarchiesInherited.of(context);
    final isCreate = inherited.typeOperation == TypeOperation.create;
    final upsertCubit = context.read<UpsertHierarchiesCubit>();
    final listCubit = context.read<HierarchiesCubit>();

    return BlocBuilder<UpsertHierarchiesCubit, UpsertHierarchiesState>(
      builder: (context, state) {
        final isLoading = state.generalStatus == GeneralStatus.loading;

        return AppFormDialog(
          title: isCreate ? 'Nueva jerarquía' : 'Editar jerarquía',
          subtitle: isCreate
              ? 'Defina código, nombre y nivel jerárquico'
              : 'Modifique los datos de la jerarquía',
          maxWidth: 480,
          isLoading: isLoading,
          submitLabel: isCreate ? 'Registrar' : 'Guardar',
          onSubmit: () {
            final validResult = inherited.valid();
            if (!validResult.isPassed) return;

            upsertCubit.save(
                entity: isCreate ? null : listCubit.state.selected,
                code: inherited.code.getValue(),
                name: inherited.name.getValue(),
                rank: int.parse(inherited.rank.getValue().trim()));
          },
          child: Form(
            key: inherited.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: inherited.code,
                  label: 'Código',
                  maxLength: 50,
                  validators: [
                    RequiredValid(error: 'Campo requerido'),
                  ],
                ),
                AppTextField(
                  controller: inherited.name,
                  label: 'Nombre',
                  maxLength: 200,
                  validators: [
                    RequiredValid(error: 'Campo requerido'),
                  ],
                ),
                AppTextField(
                    controller: inherited.rank,
                    label: 'Nivel jerárquico',
                    inputType: TextInputType.number,
                    validators: [_HierarchyRankValid()]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HierarchyRankValid extends AbstractValid {
  @override
  String? valid(String? value) {
    final rank = int.tryParse(value?.trim() ?? '');
    if (rank == null || rank < 1 || rank > 1000000) {
      return 'Ingrese un nivel entero entre 1 y 1000000.';
    }
    return null;
  }
}
