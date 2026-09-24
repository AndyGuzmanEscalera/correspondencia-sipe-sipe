import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/tables/correspondence_movements_table.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:flutter/material.dart';

class CorrespondenceMovementsSection extends StatelessWidget {
  const CorrespondenceMovementsSection({
    required this.movements,
    this.expandVertically = true,
    super.key,
  });

  final List<CorrespondenceMovementEntity> movements;
  final bool expandVertically;

  @override
  Widget build(BuildContext context) {
    final grid = Container(
      width: double.infinity,
      decoration: AppDecorations.surfaceCard(elevated: false),
      clipBehavior: Clip.antiAlias,
      child: AppDataGrid<CorrespondenceMovementEntity>(
        items: movements,
        emptyMessage: 'Sin movimientos registrados.',
        allowSorting: false,
        shrinkWrap: !expandVertically,
        columns: correspondenceMovementsTableColumns(),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: expandVertically ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const Text(
          'Movimientos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (expandVertically) Expanded(child: grid) else grid,
      ],
    );
  }
}
