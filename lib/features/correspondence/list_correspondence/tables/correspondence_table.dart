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
      key: 'documentNumber',
      label: 'N.º Doc',
      width: 100,
      value: (item) => item.documentNumber ?? '-',
      mobilePriority: 35,
      mobileVisible: false,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'documentType',
      label: 'Tipo documental',
      value: (item) => item.documentTypeLabel,
      mobilePriority: 30,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'origin',
      label: 'Origen',
      width: 100,
      value: (item) => item.originTypeLabel,
      mobilePriority: 28,
      mobileVisible: false,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'subject',
      label: 'Asunto',
      value: (item) => item.subject,
      mobilePriority: 10,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'reference',
      label: 'Referencia',
      value: (item) => item.reference ?? '-',
      mobilePriority: 32,
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
      label: 'Responsable actual',
      width: 220,
      value: (item) {
        final hasUnit = item.currentUnitName?.isNotEmpty == true;
        if (!hasUnit) {
          return item.currentResponsibleUnitLabel;
        }
        return '${item.currentResponsibleUnitLabel} · ${item.currentResponsibleUserLabel}';
      },
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

List<AppDataGridColumn<CorrespondenceEntity>> sentCorrespondenceTableColumns() {
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
      key: 'documentNumber',
      label: 'N.º Doc',
      width: 100,
      value: (item) => item.documentNumber ?? '-',
      mobilePriority: 35,
      mobileVisible: false,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'documentType',
      label: 'Tipo documental',
      value: (item) => item.documentTypeLabel,
      mobilePriority: 30,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'origin',
      label: 'Origen',
      width: 100,
      value: (item) => item.originTypeLabel,
      mobilePriority: 28,
      mobileVisible: false,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'subject',
      label: 'Asunto',
      value: (item) => item.subject,
      mobilePriority: 10,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'reference',
      label: 'Referencia',
      value: (item) => item.reference ?? '-',
      mobilePriority: 32,
      mobileVisible: false,
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
      label: 'Responsable actual',
      width: 220,
      value: (item) {
        final hasUnit = item.currentUnitName?.isNotEmpty == true;
        if (!hasUnit) {
          return item.currentResponsibleUnitLabel;
        }
        return '${item.currentResponsibleUnitLabel} · ${item.currentResponsibleUserLabel}';
      },
      mobilePriority: 20,
    ),
    AppDataGridColumn<CorrespondenceEntity>(
      key: 'lastSentAt',
      label: 'Enviado',
      type: AppDataGridCellType.dateTime,
      width: 150,
      value: (item) => item.lastSentAt,
      mobilePriority: 15,
    ),
  ];
}
