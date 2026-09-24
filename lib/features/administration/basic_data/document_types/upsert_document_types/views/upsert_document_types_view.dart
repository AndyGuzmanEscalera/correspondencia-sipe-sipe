import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/cubit/document_types_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/upsert_document_types/cubit/upsert_document_types_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/upsert_document_types/helpers/upsert_document_types_inherited.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpsertDocumentTypesPage extends StatelessWidget {
  const UpsertDocumentTypesPage({super.key, required this.typeOperation});

  final TypeOperation typeOperation;

  @override
  Widget build(BuildContext context) {
    return UpsertDocumentTypesInherited(
      typeOperation: typeOperation,
      child: BlocProvider(
        create: (context) => getIt<UpsertDocumentTypesCubit>(),
        child: const UpsertDocumentTypesView(),
      ),
    );
  }
}

class UpsertDocumentTypesView extends StatelessWidget {
  const UpsertDocumentTypesView({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertDocumentTypesInherited.of(context);
    final listCubit = context.read<DocumentTypesCubit>();

    return MultiBlocListener(
      listeners: [
        ListenerPro<UpsertDocumentTypesCubit, UpsertDocumentTypesState>().listen(
          onPressedSuccess: () => Navigator.of(context).pop(),
        ),
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

    return AlertDialog(
      title: Text(
        isCreate ? 'Nuevo tipo de documento' : 'Editar tipo de documento',
      ),
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
              const SizedBox(height: 10),
              BlocBuilder<UpsertDocumentTypesCubit, UpsertDocumentTypesState>(
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
