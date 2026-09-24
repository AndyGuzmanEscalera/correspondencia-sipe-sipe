import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class ChainingFields extends StatelessWidget {
  const ChainingFields({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);

    return Column(
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
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Indique al menos asunto o referencia.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}
