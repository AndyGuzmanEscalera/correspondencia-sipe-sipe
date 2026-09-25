import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class ChainingFields extends StatelessWidget {
  const ChainingFields({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);
    const chainingError =
        UpsertCorrespondenceInherited.chainingSubjectReferenceError;

    return UpsertFormSection(
      title: 'Contenido',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: inherited.subject,
            label: 'Asunto',
            validators: [
              AtLeastOneOfValid(
                otherValue: inherited.reference.getValue,
                error: chainingError,
              ),
            ],
            onChanged: (_) {
              inherited.reference.fieldKey.currentState?.validate();
            },
          ),
          AppTextField(
            controller: inherited.reference,
            label: 'Referencia',
            validators: [
              AtLeastOneOfValid(
                otherValue: inherited.subject.getValue,
                error: chainingError,
              ),
            ],
            onChanged: (_) {
              inherited.subject.fieldKey.currentState?.validate();
            },
          ),
          Text(
            'Indique al menos asunto o referencia.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
