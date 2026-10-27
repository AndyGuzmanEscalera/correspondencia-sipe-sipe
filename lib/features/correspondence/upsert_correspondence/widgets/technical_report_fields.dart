import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class TechnicalReportFields extends StatelessWidget {
  const TechnicalReportFields(
      {this.requireSubjectOrReference = false, super.key});
  final bool requireSubjectOrReference;

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
            inputType: TextInputType.multiline,
            maxLines: 6,
            maxLength: 10000,
            label: 'Descripción / contenido',
            validators: [
              RequiredValid(error: 'La descripción es obligatoria'),
            ],
          ),
          AppTextField(
            controller: inherited.subject,
            validators: [
              if (requireSubjectOrReference)
                AtLeastOneOfValid(
                    otherValue: inherited.reference.getValue,
                    error: UpsertCorrespondenceInherited
                        .chainingSubjectReferenceError)
            ],
            onChanged: (_) =>
                inherited.reference.fieldKey.currentState?.validate(),
            label: requireSubjectOrReference
                ? 'Asunto o referencia'
                : 'Asunto (opcional)',
          ),
          AppTextField(
            controller: inherited.reference,
            validators: [
              if (requireSubjectOrReference)
                AtLeastOneOfValid(
                    otherValue: inherited.subject.getValue,
                    error: UpsertCorrespondenceInherited
                        .chainingSubjectReferenceError)
            ],
            onChanged: (_) =>
                inherited.subject.fieldKey.currentState?.validate(),
            label: 'Referencia (opcional)',
          ),
        ],
      ),
    );
  }
}
