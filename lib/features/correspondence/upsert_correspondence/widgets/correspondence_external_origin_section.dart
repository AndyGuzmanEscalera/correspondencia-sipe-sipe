import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class CorrespondenceExternalOriginSection extends StatelessWidget {
  const CorrespondenceExternalOriginSection({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: inherited.senderName,
          label: 'Remitente externo',
          validators: [
            RequiredValid(error: 'Campo requerido'),
          ],
        ),
        AppTextField(
          controller: inherited.senderDocument,
          label: 'Documento del remitente (opcional)',
        ),
        AppTextField(
          controller: inherited.senderContact,
          label: 'Contacto del remitente (opcional)',
          inputType: TextInputType.phone,
        ),
        AppTextField(
          controller: inherited.originDescription,
          label: 'Descripción del origen (opcional)',
        ),
      ],
    );
  }
}
