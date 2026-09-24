import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_status_badge.dart';

List<AppDataGridColumn<EmployeeAdmin>> employeesTableColumns() {
  return [
    AppDataGridColumn<EmployeeAdmin>(
      key: 'name',
      label: 'Funcionario',
      value: (item) => item.fullName,
      mobilePrimary: true,
      mobilePriority: 1,
    ),
    AppDataGridColumn<EmployeeAdmin>(
      key: 'document',
      label: 'CI',
      width: 130,
      value: (item) => item.documentNumber,
      mobilePriority: 10,
    ),
    AppDataGridColumn<EmployeeAdmin>(
      key: 'unit',
      label: 'Unidad',
      value: (item) => item.unitName,
      mobilePriority: 15,
    ),
    AppDataGridColumn<EmployeeAdmin>(
      key: 'position',
      label: 'Cargo',
      value: (item) => item.positionName,
      mobilePriority: 20,
    ),
    AppDataGridColumn<EmployeeAdmin>(
      key: 'email',
      label: 'Correo',
      value: (item) => item.email,
      mobileVisible: false,
    ),
    AppDataGridColumn<EmployeeAdmin>(
      key: 'phone',
      label: 'Teléfono',
      value: (item) => item.phone,
      mobileVisible: false,
    ),
    AppDataGridColumn<EmployeeAdmin>(
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
