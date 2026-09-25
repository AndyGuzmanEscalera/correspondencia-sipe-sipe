import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:flutter/material.dart';

class DocumentTypeSection extends StatelessWidget {
  const DocumentTypeSection({
    required this.documentTypes,
    this.onDocumentTypeChanged,
    super.key,
  });

  final List<DocumentType> documentTypes;
  final ValueChanged<DocumentType>? onDocumentTypeChanged;

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);
    final docTypeItems = documentTypes
        .map(
          (item) => FormOption<String>(
            id: item.id.hashCode,
            text: item.code,
            description: item.name,
            value: item.id,
          ),
        )
        .toList();

    return UpsertFormSection(
      title: 'Documento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (docTypeItems.isEmpty)
            const Text('No hay tipos de documento disponibles.')
          else
            AppDropdown<String>(
              controller: inherited.documentType,
              label: 'Tipo de documento',
              items: docTypeItems,
              validators: [
                RequiredValid(error: 'Seleccione un tipo de documento'),
              ],
              onChanged: (option) {
                DocumentType? selected;
                for (final item in documentTypes) {
                  if (item.id == option.value) {
                    selected = item;
                    break;
                  }
                }
                if (selected != null) {
                  onDocumentTypeChanged?.call(selected);
                }
              },
            ),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              UpsertReadOnlyChip(
                label: 'Número de documento',
                value: 'Automático',
              ),
              UpsertReadOnlyChip(
                label: 'Fecha y hora de registro',
                value: 'Se asignará al registrar',
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppDropdown<String>(
            controller: inherited.priority,
            label: 'Prioridad',
            items: UpsertCorrespondenceInherited.priorityItems,
            validators: [
              RequiredValid(error: 'Seleccione una prioridad'),
            ],
          ),
        ],
      ),
    );
  }
}
