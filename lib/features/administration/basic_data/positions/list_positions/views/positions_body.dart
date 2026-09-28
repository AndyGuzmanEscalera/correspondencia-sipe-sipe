import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/cubit/positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/tables/positions_table.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/views/upsert_positions_view.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PositionsBody extends StatelessWidget {
  const PositionsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    final canManage = hasPermission(session, Permissions.positionsManage);
    final cubit = context.read<PositionsCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Cargos',
            subtitle: 'Catálogo de cargos institucionales',
            actions: [
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return BlocProvider.value(
                          value: BlocProvider.of<PositionsCubit>(context),
                          child: UpsertPositionsPage(
                            typeOperation: TypeOperation.create,
                            hostDialogContext: dialogContext,
                            ownerContext: context,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo cargo'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar por código o nombre',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          BlocBuilder<PositionsCubit, PositionsState>(
            builder: (context, state) {
              final isLoading = state.generalStatus == GeneralStatus.loading &&
                  state.list.isEmpty;
              return DataPanel(
                child: AppDataGrid<PositionAdmin>(
                  items: state.list,
                  isLoading: isLoading,
                  emptyMessage: 'No se encontraron registros con ese criterio.',
                  columns: positionsTableColumns(),
                  actions: canManage
                      ? [
                          AppDataGridAction<PositionAdmin>(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar',
                            onPressed: (item) {
                              cubit.changeSelected(item);
                              showDialog<void>(
                                context: context,
                                builder: (dialogContext) {
                                  return BlocProvider.value(
                                    value: BlocProvider.of<PositionsCubit>(
                                      context,
                                    ),
                                    child: UpsertPositionsPage(
                                      typeOperation: TypeOperation.update,
                                      hostDialogContext: dialogContext,
                                      ownerContext: context,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          AppDataGridAction<PositionAdmin>(
                            icon: Icons.toggle_on_outlined,
                            tooltip: 'Desactivar',
                            visibleWhen: (item) => item.isActive,
                            onPressed: cubit.toggleActive,
                          ),
                          AppDataGridAction<PositionAdmin>(
                            icon: Icons.toggle_off_outlined,
                            tooltip: 'Activar',
                            visibleWhen: (item) => !item.isActive,
                            onPressed: cubit.toggleActive,
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
