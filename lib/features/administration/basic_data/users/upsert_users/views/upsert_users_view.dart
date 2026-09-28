import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/cubit/users_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/cubit/upsert_users_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/helpers/upsert_users_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/widgets/user_roles_section.dart';
import 'package:correspondencia_sipe_sipe/features/administration/common/admin_upsert_bloc_listener.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/app_form_dialog.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpsertUsersPage extends StatelessWidget {
  const UpsertUsersPage({
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
    return UpsertUsersInherited(
      typeOperation: typeOperation,
      child: BlocProvider(
        create: (context) => getIt<UpsertUsersCubit>(),
        child: UpsertUsersView(
          hostDialogContext: hostDialogContext,
          ownerContext: ownerContext,
        ),
      ),
    );
  }
}

class UpsertUsersView extends StatelessWidget {
  const UpsertUsersView({
    super.key,
    this.hostDialogContext,
    this.ownerContext,
  });

  final BuildContext? hostDialogContext;
  final BuildContext? ownerContext;

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertUsersInherited.of(context);
    final listCubit = context.read<UsersCubit>();
    final upsertCubit = context.read<UpsertUsersCubit>();
    final selected = listCubit.state.selected;

    return AdminUpsertBlocListener<UpsertUsersCubit, UpsertUsersState>(
      hostDialogContext: hostDialogContext,
      ownerContext: ownerContext,
      child: MultiBlocListener(
        listeners: [
          ListenerPro<UpsertUsersCubit, UpsertUsersState>().event(
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
          child: const UpsertUsersBody(),
        ),
      ),
    );
  }
}

class UpsertUsersBody extends StatefulWidget {
  const UpsertUsersBody({super.key});

  @override
  State<UpsertUsersBody> createState() => _UpsertUsersBodyState();
}

class _UpsertUsersBodyState extends State<UpsertUsersBody> {
  bool _rolesApplied = false;

  void _applyRolesIfNeeded(UpsertUsersState state) {
    final inherited = UpsertUsersInherited.of(context);
    final selected = context.read<UsersCubit>().state.selected;
    final isCreate = inherited.typeOperation == TypeOperation.create;

    if (isCreate || selected == null || _rolesApplied || !state.catalogReady) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _rolesApplied) return;
      inherited.setRolesFromCatalog(selected, state.roles);
      setState(() => _rolesApplied = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertUsersInherited.of(context);
    final isCreate = inherited.typeOperation == TypeOperation.create;
    final upsertCubit = context.read<UpsertUsersCubit>();
    final listCubit = context.read<UsersCubit>();
    final selected = listCubit.state.selected;

    return BlocBuilder<UpsertUsersCubit, UpsertUsersState>(
      builder: (context, state) {
        _applyRolesIfNeeded(state);
        if (!state.catalogLoaded) {
          return AppFormDialog(
            title: isCreate ? 'Nuevo usuario' : 'Editar usuario',
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
            title: isCreate ? 'Nuevo usuario' : 'Editar usuario',
            maxWidth: 540,
            onSubmit: null,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No se pudieron cargar funcionarios y roles activos.',
              ),
            ),
          );
        }

        final employeeItems = state.employees
            .map(
              (employee) => FormOption<String>(
                id: employee.id.hashCode,
                text: employee.fullName,
                value: employee.id,
              ),
            )
            .toList();

        final isLoading = state.generalStatus == GeneralStatus.loading;

        return AppFormDialog(
          title: isCreate ? 'Nuevo usuario' : 'Editar usuario',
          subtitle: isCreate
              ? 'Defina credenciales y asignación de roles'
              : 'Actualice los datos y roles del usuario',
          maxWidth: 540,
          isLoading: isLoading,
          submitLabel: isCreate ? 'Registrar' : 'Guardar',
          onSubmit: () {
            final validResult =
                inherited.valid(isCreate: isCreate);
            if (!validResult.isPassed) return;

            final employeeId = inherited.employee.get();
            if (employeeId == null) return;

            final roleIds = inherited.selectedRoleIds.toList();

            if (isCreate) {
              upsertCubit.save(
                username: inherited.username.getValue(),
                employeeId: employeeId,
                initialPassword: inherited.password.getValue(),
                roleIds: roleIds,
                email: inherited.email.getValue(),
              );
            } else {
              if (selected == null) return;
              upsertCubit.update(
                entity: selected,
                username: inherited.username.getValue(),
                employeeId: employeeId,
                roleIds: roleIds,
                email: inherited.email.getValue(),
              );
            }
          },
          child: Form(
            key: inherited.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: inherited.username,
                  label: 'Nombre de usuario',
                  validators: [
                    RequiredValid(error: 'Campo requerido'),
                  ],
                ),
                AppTextField(
                  controller: inherited.email,
                  label: 'Correo (opcional)',
                  inputType: TextInputType.emailAddress,
                ),
                if (isCreate)
                  AppTextPassword(
                    controller: inherited.password,
                    label: 'Contraseña inicial',
                    validators: [
                      RequiredValid(error: 'Campo requerido'),
                    ],
                  ),
                AppDropdown<String>(
                  controller: inherited.employee,
                  label: 'Funcionario',
                  items: employeeItems,
                  validators: [
                    RequiredValid(error: 'Seleccione un funcionario'),
                  ],
                ),
                UserRolesSection(roles: state.roles),
              ],
            ),
          ),
        );
      },
    );
  }
}
