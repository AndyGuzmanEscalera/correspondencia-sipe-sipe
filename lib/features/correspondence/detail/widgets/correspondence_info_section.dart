import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_info_tile.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CorrespondenceInfoSection extends StatelessWidget {
  const CorrespondenceInfoSection(
      {required this.item, this.expandInParent = false, super.key});
  final CorrespondenceEntity item;
  final bool expandInParent;

  @override
  Widget build(BuildContext context) {
    final groups = [
      _InfoGroup(title: 'Documento', fields: [
        CorrespondenceInfoTile(label: 'Hoja de Ruta', value: item.routeNumber),
        if (item.documentNumber?.isNotEmpty ?? false)
          CorrespondenceInfoTile(
              label: 'N.º documento', value: item.documentNumber!),
        if (item.cite.isNotEmpty && item.cite != item.routeNumber)
          CorrespondenceInfoTile(label: 'CITE', value: item.cite),
        CorrespondenceInfoTile(
            label: 'Tipo de documento', value: item.documentTypeName),
      ]),
      _InfoGroup(title: 'Origen y responsable', fields: [
        CorrespondenceInfoTile(label: 'Origen', value: item.originTypeLabel),
        CorrespondenceInfoTile(label: 'DE', value: item.originLabel),
        if (item.originDescription?.isNotEmpty ?? false)
          CorrespondenceInfoTile(
              label: 'Descripción del origen', value: item.originDescription!),
        CorrespondenceInfoTile(
            label: 'Responsable actual',
            value: item.currentResponsibleUnitLabel),
        CorrespondenceInfoTile(
            label: 'Usuario responsable',
            value: item.currentResponsibleUserLabel),
      ]),
      _InfoGroup(title: 'Registro', fields: [
        CorrespondenceInfoTile(label: 'Prioridad', value: item.priority),
        if (item.createdByUsername?.isNotEmpty ?? false)
          CorrespondenceInfoTile(
              label: 'Registrado por', value: item.createdByUsername!),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: CorrespondenceInfoTile(
                  label: 'Fecha de registro',
                  value: DateFormat('dd/MM/yyyy').format(item.registeredAt))),
          const SizedBox(width: 12),
          Expanded(
              child: CorrespondenceInfoTile(
                  label: 'Hora',
                  value: DateFormat('HH:mm').format(item.registeredAt))),
        ]),
      ]),
    ];
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text('Información del documento',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: UiColors.textPrimary)),
              StatusBadge(label: item.statusLabel),
            ]),
        const SizedBox(height: 16),
        CorrespondenceInfoTile(label: 'Asunto', value: item.subject),
        if (item.reference?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          CorrespondenceInfoTile(label: 'Referencia', value: item.reference!),
        ],
        if (item.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          CorrespondenceInfoTile(
              label: 'Descripción', value: item.description!),
        ],
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: UiColors.border)),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1000
              ? 3
              : constraints.maxWidth >= 620
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - (columns - 1) * 28) / columns;
          return Wrap(spacing: 28, runSpacing: 20, children: [
            for (var i = 0; i < groups.length; i++)
              SizedBox(
                  width: columns == 2 && i == 2 ? constraints.maxWidth : width,
                  child: groups[i]),
          ]);
        }),
      ],
    );
    if (expandInParent) return DataPanel(child: content);
    return Container(
        width: double.infinity,
        decoration: AppDecorations.surfaceCard(elevated: false),
        padding: const EdgeInsets.all(20),
        child: content);
  }
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.title, required this.fields});
  final String title;
  final List<Widget> fields;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: UiColors.primary)),
          const SizedBox(height: 12),
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            fields[i],
          ],
        ],
      );
}
