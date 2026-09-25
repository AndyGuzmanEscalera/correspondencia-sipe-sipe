import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_status_badge.dart';
List<AppDataGridColumn<CorrespondenceMovementEntity>>
    correspondenceMovementsTableColumns() {
  return [
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'sequence',
      label: 'Sec.',
      type: AppDataGridCellType.integer,
      width: 72,
      value: (movement) => movement.sequenceNumber,
      mobilePriority: 5,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'type',
      label: 'Tipo',
      value: (movement) => movement.movementTypeLabel,
      mobilePrimary: true,
      mobilePriority: 1,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'fromUnit',
      label: 'Desde unidad',
      value: (movement) => movement.fromUnitName,
      mobilePriority: 15,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'fromUser',
      label: 'Desde usuario',
      value: (movement) => movement.fromUserName,
      mobilePriority: 20,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'toUnit',
      label: 'Hacia unidad',
      value: (movement) => movement.toUnitName,
      mobilePriority: 25,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'toUser',
      label: 'Hacia usuario',
      value: (movement) => movement.toUserName,
      mobilePriority: 30,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'instruction',
      label: 'Instrucción',
      value: (movement) => movement.instruction,
      mobilePriority: 35,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'observation',
      label: 'Observación',
      value: (movement) => movement.observation,
      mobilePriority: 36,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'createdAt',
      label: 'Fecha',
      type: AppDataGridCellType.dateTime,
      width: 150,
      value: (movement) => movement.createdAt,
      mobilePriority: 10,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'status',
      label: 'Estado',
      type: AppDataGridCellType.status,
      width: 120,
      sortable: false,
      value: (movement) => movement.isCancelled,
      mobilePriority: 3,
      cellBuilder: (context, movement, value) {
        if (movement.isCancelled) {
          return const AppStatusBadge.inactive('Cancelado');
        }
        return const AppStatusBadge.success('Vigente');
      },
    ),
  ];
}
