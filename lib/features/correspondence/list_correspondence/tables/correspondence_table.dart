import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';

List<AppDataGridColumn<CorrespondenceEntity>> correspondenceTableColumns() {
  return [
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'routeNumber',
      label: 'HR',
      width: 150,
      value: (item) => item.routeNumber,
      mobilePrimary: true,
      mobilePriority: 1,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'subject',
      label: 'Asunto',
      value: (item) => item.subject,
      mobilePriority: 10,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'type',
      label: 'Tipo',
      value: (item) => item.typeLabel,
      mobilePriority: 30,
      mobileVisible: false,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'priority',
      label: 'Prioridad',
      value: (item) => item.priority,
      mobilePriority: 25,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'status',
      label: 'Estado',
      type: AppDataGridCellType.status,
      width: 130,
      value: (item) => item.statusLabel,
      mobilePriority: 5,
      cellBuilder: (context, item, value) =>
          StatusBadge(label: value?.toString() ?? '-'),
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'responsible',
      label: 'Responsable',
      value: (item) => item.currentResponsibleLabel,
      mobilePriority: 20,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'registeredAt',
      label: 'Fecha',
      type: AppDataGridCellType.date,
      width: 120,
      value: (item) => item.registeredAt,
      mobilePriority: 15,
    ),
  ];
}
