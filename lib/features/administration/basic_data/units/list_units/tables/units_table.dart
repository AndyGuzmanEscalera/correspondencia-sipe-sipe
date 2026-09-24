import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_status_badge.dart';

List<AppDataGridColumn<OrganizationalUnitAdmin>> unitsTableColumns() {
  return [
    AppDataGridColumn<OrganizationalUnitAdmin>(
      key: 'code',
      label: 'Código',
      width: 120,
      value: (item) => item.code,
      mobilePriority: 20,
    ),
    AppDataGridColumn<OrganizationalUnitAdmin>(
      key: 'name',
      label: 'Nombre',
      value: (item) => item.name,
      mobilePrimary: true,
      mobilePriority: 1,
    ),
    AppDataGridColumn<OrganizationalUnitAdmin>(
      key: 'parent',
      label: 'Unidad superior',
      value: (item) => item.parentName,
      mobilePriority: 15,
    ),
    AppDataGridColumn<OrganizationalUnitAdmin>(
      key: 'active',
      label: 'Estado',
      type: AppDataGridCellType.status,
      width: 110,
      value: (item) => item.isActive,
      mobilePriority: 5,
      cellBuilder: (context, item, value) {
        final active = value == true;
        return active
            ? const AppStatusBadge.success('Activo')
            : const AppStatusBadge.inactive('Inactivo');
      },
    ),
  ];
}
