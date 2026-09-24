import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class CorrespondenceBasicInformationSection extends StatelessWidget {
  const CorrespondenceBasicInformationSection({
    required this.documentTypes,
    required this.onTypeChanged,
    super.key,
  });

  final List<DocumentType> documentTypes;
  final ValueChanged<CorrespondenceTypeCode> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);
    final docTypeItems = documentTypes
        .map(
          (item) => FormOption<String>(
            id: item.id.hashCode,
            text: item.name,
            value: item.id,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: inherited.subject,
          label: 'Asunto',
          validators: [
            RequiredValid(error: 'Campo requerido'),
          ],
        ),
        AppTextField(
          controller: inherited.reference,
          label: 'Referencia (opcional)',
        ),
        if (docTypeItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No hay tipos de documento disponibles.'),
          )
        else
          AppDropdown<String>(
            controller: inherited.documentType,
            label: 'Tipo de documento',
            items: docTypeItems,
            validators: [
              RequiredValid(error: 'Seleccione un tipo de documento'),
            ],
          ),
        AppDropdown<CorrespondenceTypeCode>(
          controller: inherited.type,
          label: 'Tipo de correspondencia',
          items: UpsertCorrespondenceInherited.typeItems,
          onChanged: (option) {
            onTypeChanged(option.value!);
          },
        ),
        AppDropdown<String>(
          controller: inherited.priority,
          label: 'Prioridad',
          items: UpsertCorrespondenceInherited.priorityItems,
          validators: [
            RequiredValid(error: 'Seleccione una prioridad'),
          ],
        ),
      ],
    );
  }
}
