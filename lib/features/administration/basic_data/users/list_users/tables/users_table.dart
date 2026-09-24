import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_status_badge.dart';

List<AppDataGridColumn<UserAdmin>> usersTableColumns() {
  return [
    AppDataGridColumn<UserAdmin>(
      key: 'username',
      label: 'Usuario',
      value: (item) => item.username,
      mobilePrimary: true,
      mobilePriority: 1,
    ),
    AppDataGridColumn<UserAdmin>(
      key: 'employee',
      label: 'Funcionario',
      value: (item) => item.employeeName,
      mobilePriority: 10,
    ),
    AppDataGridColumn<UserAdmin>(
      key: 'unit',
      label: 'Unidad',
      value: (item) => item.unitName,
      mobilePriority: 15,
    ),
    AppDataGridColumn<UserAdmin>(
      key: 'roles',
      label: 'Roles',
      value: (item) => item.roleCodes.join(', '),
      mobilePriority: 25,
    ),
    AppDataGridColumn<UserAdmin>(
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
