import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/upsert_employees/cubit/upsert_employees_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/upsert_employees/helpers/upsert_employees_inherited.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/app_form_dialog.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpsertEmployeesPage extends StatelessWidget {
  const UpsertEmployeesPage({super.key, required this.typeOperation});

  final TypeOperation typeOperation;

  @override
  Widget build(BuildContext context) {
    return UpsertEmployeesInherited(
      typeOperation: typeOperation,
      child: BlocProvider(
        create: (context) => getIt<UpsertEmployeesCubit>(),
        child: const UpsertEmployeesView(),
      ),
    );
  }
}

class UpsertEmployeesView extends StatelessWidget {
  const UpsertEmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertEmployeesInherited.of(context);
    final listCubit = context.read<EmployeesCubit>();
    final upsertCubit = context.read<UpsertEmployeesCubit>();
    final selected = listCubit.state.selected;

    return MultiBlocListener(
      listeners: [
        ListenerPro<UpsertEmployeesCubit, UpsertEmployeesState>().listen(
          onPressedSuccess: () => Navigator.of(context).pop(),
        ),
        ListenerPro<UpsertEmployeesCubit, UpsertEmployeesState>().event(
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
        child: const UpsertEmployeesBody(),
      ),
    );
  }
}

class UpsertEmployeesBody extends StatelessWidget {
  const UpsertEmployeesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertEmployeesInherited.of(context);
    final isCreate = inherited.typeOperation == TypeOperation.create;
    final upsertCubit = context.read<UpsertEmployeesCubit>();
    final listCubit = context.read<EmployeesCubit>();
    final selected = listCubit.state.selected;

    return BlocBuilder<UpsertEmployeesCubit, UpsertEmployeesState>(
      builder: (context, state) {
        if (!state.catalogLoaded) {
          return AppFormDialog(
            title: isCreate ? 'Nuevo funcionario' : 'Editar funcionario',
            maxWidth: 540,
            isLoading: true,
            isSubmitDisabled: true,
            child: const SizedBox(
              height: 120,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          );
        }

        if (!state.catalogReady) {
          return AppFormDialog(
            title: isCreate ? 'Nuevo funcionario' : 'Editar funcionario',
            maxWidth: 540,
            onSubmit: null,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No se pudieron cargar unidades y cargos activos.',
              ),
            ),
          );
        }

        final unitItems = state.units
            .map(
              (unit) => FormOption<String>(
                id: unit.id.hashCode,
                text: unit.name,
                value: unit.id,
              ),
            )
            .toList();
        final positionItems = state.positions
            .map(
              (position) => FormOption<String>(
                id: position.id.hashCode,
                text: position.name,
                value: position.id,
              ),
            )
            .toList();

        final isLoading = state.generalStatus == GeneralStatus.loading;

        return AppFormDialog(
          title: isCreate ? 'Nuevo funcionario' : 'Editar funcionario',
          subtitle: isCreate
              ? 'Complete los datos personales y de asignación'
              : 'Actualice los datos del funcionario',
          maxWidth: 540,
          isLoading: isLoading,
          submitLabel: isCreate ? 'Registrar' : 'Guardar',
          onSubmit: () {
            final validResult = inherited.valid();
            if (!validResult.isPassed) return;

            final unitId = inherited.unit.get();
            final positionId = inherited.position.get();
            if (unitId == null || positionId == null) return;

            if (isCreate) {
              upsertCubit.save(
                firstName: inherited.firstName.getValue(),
                lastName: inherited.lastName.getValue(),
                documentNumber: inherited.document.getValue(),
                unitId: unitId,
                positionId: positionId,
                email: inherited.email.getValue(),
                phone: inherited.phone.getValue(),
              );
            } else {
              if (selected == null) return;
              upsertCubit.update(
                entity: selected,
                firstName: inherited.firstName.getValue(),
                lastName: inherited.lastName.getValue(),
                documentNumber: inherited.document.getValue(),
                unitId: unitId,
                positionId: positionId,
                email: inherited.email.getValue(),
                phone: inherited.phone.getValue(),
              );
            }
          },
          child: Form(
            key: inherited.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: inherited.firstName,
                  label: 'Nombres',
                  validators: [
                    RequiredValid(error: 'Campo requerido'),
                  ],
                ),
                AppTextField(
                  controller: inherited.lastName,
                  label: 'Apellidos',
                  validators: [
                    RequiredValid(error: 'Campo requerido'),
                  ],
                ),
                AppTextField(
                  controller: inherited.document,
                  label: 'Documento de identidad',
                  validators: [
                    RequiredValid(error: 'Campo requerido'),
                  ],
                ),
                AppTextField(
                  controller: inherited.email,
                  label: 'Correo (opcional)',
                  inputType: TextInputType.emailAddress,
                ),
                AppTextField(
                  controller: inherited.phone,
                  label: 'Teléfono (opcional)',
                  inputType: TextInputType.phone,
                ),
                AppDropdown<String>(
                  controller: inherited.unit,
                  label: 'Unidad',
                  items: unitItems,
                  validators: [
                    RequiredValid(error: 'Seleccione una unidad'),
                  ],
                ),
                AppDropdown<String>(
                  controller: inherited.position,
                  label: 'Cargo',
                  items: positionItems,
                  validators: [
                    RequiredValid(error: 'Seleccione un cargo'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
