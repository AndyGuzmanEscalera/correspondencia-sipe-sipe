import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class RouteSheetFields extends StatelessWidget {
  const RouteSheetFields({required this.paraLabel, super.key});
  final String? paraLabel;

  @override
  Widget build(BuildContext context) {
    final fields = UpsertCorrespondenceInherited.of(context);
    return UpsertFormSection(
      title: 'Hoja de Ruta',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('PARA: ${paraLabel ?? "Configure la autoridad institucional"}',
            key: const Key('route-sheet-para')),
        const SizedBox(height: 12),
        AppTextField(
            controller: fields.reference,
            label: 'Referencia',
            maxLength: 200,
            validators: [RequiredValid()]),
        AppTextField(
            controller: fields.description,
            label: 'Texto / contenido',
            maxLength: 10000,
            maxLines: 5,
            inputType: TextInputType.multiline,
            validators: [RequiredValid()]),
        const Text(
          'La fecha y hora de emisión y el número de hojas se generan automáticamente al guardar.',
          key: Key('route-sheet-automatic-issuance'),
        ),
      ]),
    );
  }
}
