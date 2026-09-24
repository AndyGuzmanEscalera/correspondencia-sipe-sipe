import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';

class CorrespondenceDetailHeader extends StatelessWidget {
  const CorrespondenceDetailHeader({
    required this.item,
    required this.onBack,
    super.key,
  });

  final CorrespondenceEntity item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'Detalle de correspondencia',
      subtitle: item.cite.isNotEmpty ? item.cite : item.routeNumber,
      actions: [
        OutlinedButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Volver'),
        ),
      ],
    );
  }
}
