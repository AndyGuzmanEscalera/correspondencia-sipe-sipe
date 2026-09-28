import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/administration/common/admin_upsert_bloc_listener.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/cubit/document_types_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/upsert_document_types/cubit/upsert_document_types_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/upsert_document_types/helpers/upsert_document_types_inherited.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/app_form_dialog.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpsertDocumentTypesPage extends StatelessWidget {
  const UpsertDocumentTypesPage({
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
    return UpsertDocumentTypesInherited(
      typeOperation: typeOperation,
      child: BlocProvider(
        create: (context) => getIt<UpsertDocumentTypesCubit>(),
        child: UpsertDocumentTypesView(
          hostDialogContext: hostDialogContext,
          ownerContext: ownerContext,
        ),
      ),
    );
  }
}

class UpsertDocumentTypesView extends StatelessWidget {
  const UpsertDocumentTypesView({
    super.key,
    this.hostDialogContext,
    this.ownerContext,
  });

  final BuildContext? hostDialogContext;
  final BuildContext? ownerContext;

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertDocumentTypesInherited.of(context);
    final listCubit = context.read<DocumentTypesCubit>();

    return AdminUpsertBlocListener<
        UpsertDocumentTypesCubit, UpsertDocumentTypesState>(
      hostDialogContext: hostDialogContext,
      ownerContext: ownerContext,
      child: MultiBlocListener(
        listeners: [
          ListenerPro<UpsertDocumentTypesCubit, UpsertDocumentTypesState>().event(
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
          child: const UpsertDocumentTypesBody(),
        ),
      ),
    );
  }
}

class UpsertDocumentTypesBody extends StatelessWidget {
  const UpsertDocumentTypesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertDocumentTypesInherited.of(context);
    final isCreate = inherited.typeOperation == TypeOperation.create;
    final upsertCubit = context.read<UpsertDocumentTypesCubit>();
    final listCubit = context.read<DocumentTypesCubit>();

    return BlocBuilder<UpsertDocumentTypesCubit, UpsertDocumentTypesState>(
      builder: (context, state) {
        final isLoading = state.generalStatus == GeneralStatus.loading;

        return AppFormDialog(
          title: isCreate
              ? 'Nuevo tipo de documento'
              : 'Editar tipo de documento',
          subtitle: isCreate
              ? 'Defina el código y nombre del tipo de documento'
              : 'Modifique los datos del tipo de documento',
          maxWidth: 480,
          isLoading: isLoading,
          submitLabel: isCreate ? 'Registrar' : 'Guardar',
          onSubmit: () {
            final validResult = inherited.valid();
            if (validResult.isPassed) {
              if (isCreate) {
                upsertCubit.save(
                  code: inherited.code.getValue(),
                  name: inherited.name.getValue(),
                );
              } else {
                final selected = listCubit.state.selected;
                if (selected == null) return;
                upsertCubit.update(
                  name: inherited.name.getValue(),
                  entity: selected,
                );
              }
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
              ],
            ),
          ),
        );
      },
    );
  }
}
