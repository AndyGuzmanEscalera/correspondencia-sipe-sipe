import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class ChainingFields extends StatelessWidget {
  const ChainingFields({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);

    return UpsertFormSection(
      title: 'Contenido',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: inherited.subject,
            label: 'Asunto',
          ),
          AppTextField(
            controller: inherited.reference,
            label: 'Referencia',
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
