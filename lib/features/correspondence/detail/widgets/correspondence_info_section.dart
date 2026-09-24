import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_info_tile.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CorrespondenceInfoSection extends StatelessWidget {
  const CorrespondenceInfoSection({
    required this.item,
    super.key,
  });

  final CorrespondenceEntity item;

  @override
  Widget build(BuildContext context) {
    return DataPanel(
      child: Wrap(
        spacing: 32,
        runSpacing: 12,
        children: [
          CorrespondenceInfoTile(label: 'HR', value: item.routeNumber),
          if (item.cite.isNotEmpty)
            CorrespondenceInfoTile(label: 'CITE', value: item.cite),
          CorrespondenceInfoTile(
            label: 'Tipo de documento',
            value: item.documentTypeName,
          ),
          CorrespondenceInfoTile(
            label: 'Tipo de correspondencia',
            value: item.typeLabel,
          ),
          if (item.documentNumber != null && item.documentNumber!.isNotEmpty)
            CorrespondenceInfoTile(
              label: 'Número de documento',
              value: item.documentNumber!,
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
            label: item.type == CorrespondenceTypeCode.ce
                ? 'Remitente'
                : 'Origen',
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
            value: item.currentResponsibleLabel,
          ),
          if (item.externalRecipient.isNotEmpty)
            CorrespondenceInfoTile(
              label: 'Unidad actual',
              value: item.externalRecipient,
            ),
          CorrespondenceInfoTile(label: 'Estado', value: item.statusLabel),
          CorrespondenceInfoTile(
            label: 'Fecha registro',
            value: DateFormat('dd/MM/yyyy').format(item.registeredAt),
          ),
          StatusBadge(label: item.statusLabel),
        ],
      ),
    );
  }
}
