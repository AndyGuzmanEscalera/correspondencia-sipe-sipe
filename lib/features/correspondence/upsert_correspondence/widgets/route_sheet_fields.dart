import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class RouteSheetDateValid extends AbstractValid {
  @override
  String? valid(String? value) {
    final text = value?.trim() ?? '';
    final parsed = DateTime.tryParse(text);
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) &&
            parsed != null &&
            parsed.toIso8601String().startsWith(text)
        ? null
        : 'Ingrese una fecha válida: AAAA-MM-DD';
  }
}

class RouteSheetTimeValid extends AbstractValid {
  @override
  String? valid(String? value) =>
      RegExp(r'^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$')
              .hasMatch(value?.trim() ?? '')
          ? null
          : 'Ingrese una hora válida: HH:MM';
}

class RouteSheetPagesValid extends AbstractValid {
  @override
  String? valid(String? value) =>
      (int.tryParse(value?.trim() ?? '') ?? 0) > 0 &&
              (int.tryParse(value?.trim() ?? '') ?? 0) <= 2147483647
          ? null
          : 'Ingrese un número de hojas mayor a cero';
}

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
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: AppTextField(
                  controller: fields.emissionDate,
                  label: 'Fecha de emisión (AAAA-MM-DD)',
                  validators: [RouteSheetDateValid()])),
          const SizedBox(width: 12),
          Expanded(
              child: AppTextField(
                  controller: fields.emissionTime,
                  label: 'Hora de emisión (HH:MM)',
                  validators: [RouteSheetTimeValid()])),
        ]),
        AppTextField(
            controller: fields.pageCount,
            label: 'Número de hojas',
            inputType: TextInputType.number,
            validators: [RouteSheetPagesValid()]),
      ]),
    );
  }
}
