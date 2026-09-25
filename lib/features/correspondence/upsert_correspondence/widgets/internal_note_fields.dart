import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class InternalNoteFields extends StatelessWidget {
  const InternalNoteFields({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);

    return UpsertFormSection(
      title: 'Contenido',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        AppTextField(
          controller: inherited.description,
          label: 'Contenido de la nota',
          validators: [
            RequiredValid(error: 'El contenido es obligatorio'),
          ],
        ),
        AppTextField(
          controller: inherited.subject,
          label: 'Asunto (opcional)',
        ),
        ],
      ),
    );
  }
}
