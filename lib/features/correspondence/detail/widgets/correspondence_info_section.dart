import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_info_tile.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CorrespondenceInfoSection extends StatelessWidget {
  const CorrespondenceInfoSection({
    required this.item,
    this.expandInParent = false,
    super.key,
  });

  final CorrespondenceEntity item;
  final bool expandInParent;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    final content = Wrap(
        spacing: 32,
        runSpacing: 12,
        children: [
          CorrespondenceInfoTile(
            label: 'Hoja de Ruta',
            value: item.routeNumber,
          ),
          if (item.documentNumber != null && item.documentNumber!.isNotEmpty)
            CorrespondenceInfoTile(
              label: 'N.º documento',
              value: item.documentNumber!,
            ),
          if (item.cite.isNotEmpty)
            CorrespondenceInfoTile(label: 'CITE', value: item.cite),
          CorrespondenceInfoTile(
            label: 'Tipo de documento',
            value: item.documentTypeName,
          ),
          CorrespondenceInfoTile(
            label: 'Origen',
            value: item.originTypeLabel,
          ),
          CorrespondenceInfoTile(label: 'Asunto', value: item.subject),
          if (item.description != null && item.description!.isNotEmpty)
            CorrespondenceInfoTile(
              label: 'Descripción',
              value: item.description!,
            ),
          if (item.reference != null && item.reference!.isNotEmpty)
            CorrespondenceInfoTile(
              label: 'Referencia',
              value: item.reference!,
            ),
          CorrespondenceInfoTile(label: 'Prioridad', value: item.priority),
          CorrespondenceInfoTile(
            label: 'DE',
            value: item.originLabel,
          ),
          if (item.originDescription != null &&
              item.originDescription!.isNotEmpty)
            CorrespondenceInfoTile(
              label: 'Descripción del origen',
              value: item.originDescription!,
            ),
          CorrespondenceInfoTile(
            label: 'Responsable actual',
            value: item.currentResponsibleUnitLabel,
          ),
          CorrespondenceInfoTile(
            label: 'Usuario responsable',
            value: item.currentResponsibleUserLabel,
          ),
          if (item.createdByUsername != null &&
              item.createdByUsername!.isNotEmpty)
            CorrespondenceInfoTile(
              label: 'Registrado por',
              value: item.createdByUsername!,
            ),
          CorrespondenceInfoTile(label: 'Estado', value: item.statusLabel),
          CorrespondenceInfoTile(
            label: 'Fecha de registro',
            value: dateFormat.format(item.registeredAt),
          ),
          CorrespondenceInfoTile(
            label: 'Hora',
            value: timeFormat.format(item.registeredAt),
          ),
          StatusBadge(label: item.statusLabel),
        ],
      );

    if (expandInParent) {
      return DataPanel(child: content);
    }

    return Container(
      width: double.infinity,
      decoration: AppDecorations.surfaceCard(elevated: false),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(16),
      child: content,
    );
  }
}
