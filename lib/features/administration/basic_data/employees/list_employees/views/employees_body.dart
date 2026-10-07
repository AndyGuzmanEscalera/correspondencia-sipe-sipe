import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/common/admin_logical_delete_dialog.dart';
import 'package:correspondencia_sipe_sipe/features/administration/common/admin_active_filter.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/tables/employees_table.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/upsert_employees/views/upsert_employees_view.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeesBody extends StatelessWidget {
  const EmployeesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    final canManage = hasPermission(session, Permissions.employeesManage);
    final cubit = context.read<EmployeesCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Funcionarios',
            subtitle: 'Personal institucional vinculado al sistema',
            actions: [
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return BlocProvider.value(
                          value: BlocProvider.of<EmployeesCubit>(context),
                          child: UpsertEmployeesPage(
                            typeOperation: TypeOperation.create,
                            hostDialogContext: dialogContext,
                            ownerContext: context,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo funcionario'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar funcionario, cargo o unidad',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          AdminActiveFilter(onChanged: cubit.filterActive),
          const SizedBox(height: 12),
          BlocBuilder<EmployeesCubit, EmployeesState>(
            builder: (context, state) {
              final isLoading = state.generalStatus == GeneralStatus.loading &&
                  state.list.isEmpty;
              return DataPanel(
                child: AppDataGrid<EmployeeAdmin>(
                  items: state.list,
                  isLoading: isLoading,
                  emptyMessage: 'No se encontraron registros con ese criterio.',
                  columns: employeesTableColumns(),
                  actions: canManage
                      ? [
                          AppDataGridAction<EmployeeAdmin>(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar',
                            onPressed: (item) {
                              cubit.changeSelected(item);
                              showDialog<void>(
                                context: context,
                                builder: (dialogContext) {
                                  return BlocProvider.value(
                                    value: BlocProvider.of<EmployeesCubit>(
                                      context,
                                    ),
                                    child: UpsertEmployeesPage(
                                      typeOperation: TypeOperation.update,
                                      hostDialogContext: dialogContext,
                                      ownerContext: context,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          AppDataGridAction<EmployeeAdmin>(
                            icon: Icons.check_circle_outline,
                            tooltip: 'Activar',
                            visibleWhen: (item) => !item.isActive,
                            onPressed: cubit.reactivate,
                          ),
                          AppDataGridAction<EmployeeAdmin>(
                            icon: Icons.delete_outline,
                            tooltip: 'Desactivar',
                            visibleWhen: (item) => item.isActive,
                            onPressed: (item) async {
                              final confirmed = await confirmAdminLogicalDelete(
                                context,
                                title: 'Desactivar funcionario',
                                message: '¿Desactivar a "${item.fullName}"? '
                                    'Dejará de estar disponible (eliminación lógica).',
                              );
                              if (confirmed && context.mounted) {
                                await cubit.deleteLogically(item);
                              }
                            },
                          ),
                        ]
                      : const [],
                  currentPage: state.page,
                  pageSize: state.pageSize,
                  totalItems: state.total,
                  totalPages: state.totalPages,
                  onPageChanged: cubit.changePage,
                  onPageSizeChanged: cubit.changePageSize,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
