import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class TechnicalReportFields extends StatelessWidget {
  const TechnicalReportFields({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: inherited.description,
          label: 'Descripción / contenido',
          validators: [
            RequiredValid(error: 'La descripción es obligatoria'),
          ],
        ),
        AppTextField(
          controller: inherited.subject,
          label: 'Asunto (opcional)',
        ),
        AppTextField(
          controller: inherited.reference,
          label: 'Referencia (opcional)',
        ),
      ],
    );
  }
}
