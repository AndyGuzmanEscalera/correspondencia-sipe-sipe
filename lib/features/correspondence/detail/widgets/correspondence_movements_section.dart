import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/tables/correspondence_movements_table.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:flutter/material.dart';

class CorrespondenceMovementsSection extends StatelessWidget {
  const CorrespondenceMovementsSection({
    required this.movements,
    super.key,
  });

  final List<CorrespondenceMovementEntity> movements;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Movimientos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: AppDecorations.surfaceCard(elevated: false),
            clipBehavior: Clip.antiAlias,
            child: AppDataGrid<CorrespondenceMovementEntity>(
              items: movements,
              emptyMessage: 'Sin movimientos registrados.',
              allowSorting: false,
              columns: correspondenceMovementsTableColumns(),
            ),
          ),
        ),
      ],
    );
  }
}
