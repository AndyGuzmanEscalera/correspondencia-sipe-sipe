import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/cubit/hierarchies_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/common/admin_logical_delete_dialog.dart';
import 'package:correspondencia_sipe_sipe/features/administration/common/admin_active_filter.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/tables/hierarchies_table.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/upsert_hierarchies/views/upsert_hierarchies_view.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HierarchiesBody extends StatelessWidget {
  const HierarchiesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    final canManage = hasPermission(session, Permissions.positionsManage);
    final cubit = context.read<HierarchiesCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Jerarquías',
            subtitle: 'Catálogo de jerarquías institucionales',
            actions: [
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return BlocProvider.value(
                          value: BlocProvider.of<HierarchiesCubit>(context),
                          child: UpsertHierarchiesPage(
                            typeOperation: TypeOperation.create,
                            hostDialogContext: dialogContext,
                            ownerContext: context,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva jerarquía'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar por código o nombre',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          AdminActiveFilter(
              onChanged: cubit.filterActive, inactiveLabel: 'Inactivas'),
          const SizedBox(height: 12),
          BlocBuilder<HierarchiesCubit, HierarchiesState>(
            builder: (context, state) {
              final isLoading = state.generalStatus == GeneralStatus.loading &&
                  state.list.isEmpty;
              return DataPanel(
                child: AppDataGrid<PositionHierarchy>(
                  items: state.list,
                  isLoading: isLoading,
                  emptyMessage: 'No se encontraron registros con ese criterio.',
                  columns: hierarchiesTableColumns(),
                  actions: canManage
                      ? [
                          AppDataGridAction<PositionHierarchy>(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar',
                            onPressed: (item) {
                              cubit.changeSelected(item);
                              showDialog<void>(
                                context: context,
                                builder: (dialogContext) {
                                  return BlocProvider.value(
                                    value: BlocProvider.of<HierarchiesCubit>(
                                      context,
                                    ),
                                    child: UpsertHierarchiesPage(
                                      typeOperation: TypeOperation.update,
                                      hostDialogContext: dialogContext,
                                      ownerContext: context,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          AppDataGridAction<PositionHierarchy>(
                            icon: Icons.check_circle_outline,
                            tooltip: 'Activar',
                            visibleWhen: (item) => !item.isActive,
                            onPressed: cubit.reactivate,
                          ),
                          AppDataGridAction<PositionHierarchy>(
                            icon: Icons.delete_outline,
                            tooltip: 'Desactivar',
                            visibleWhen: (item) => item.isActive,
                            onPressed: (item) async {
                              final confirmed = await confirmAdminLogicalDelete(
                                context,
                                title: 'Desactivar jerarquía',
                                confirmLabel: 'Desactivar',
                                message:
                                    '¿Está seguro de desactivar la jerarquía "${item.name}"? '
                                    'Dejará de estar disponible para nuevas operaciones. Su historial se conservará.',
                              );
                              if (confirmed && context.mounted) {
                                await cubit.deactivate(item);
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
