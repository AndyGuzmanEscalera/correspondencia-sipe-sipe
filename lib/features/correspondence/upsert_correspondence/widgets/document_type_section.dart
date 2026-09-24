import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
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
            text: '${item.name} (${item.code})',
            value: item.id,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (docTypeItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No hay tipos de documento disponibles.'),
          )
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
        const _ReadOnlyField(
          label: 'Número de documento',
          value: 'Automático',
        ),
        const _ReadOnlyField(
          label: 'Fecha y hora de registro',
          value: 'Se asignará al registrar',
        ),
        AppDropdown<String>(
          controller: inherited.priority,
          label: 'Prioridad',
          items: UpsertCorrespondenceInherited.priorityItems,
          validators: [
            RequiredValid(error: 'Seleccione una prioridad'),
          ],
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
