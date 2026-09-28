import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/cubit/units_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/tables/units_table.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/upsert_units/views/upsert_units_view.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnitsBody extends StatelessWidget {
  const UnitsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    final canManage =
        hasPermission(session, Permissions.organizationalUnitsManage);
    final cubit = context.read<UnitsCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Unidades organizacionales',
            subtitle: 'Estructura orgánica institucional',
            actions: [
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return BlocProvider.value(
                          value: BlocProvider.of<UnitsCubit>(context),
                          child: UpsertUnitsPage(
                            typeOperation: TypeOperation.create,
                            hostDialogContext: dialogContext,
                            ownerContext: context,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva unidad'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar por código o nombre',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          BlocBuilder<UnitsCubit, UnitsState>(
            builder: (context, state) {
              final isLoading = state.generalStatus == GeneralStatus.loading &&
                  state.list.isEmpty;
              return DataPanel(
                child: AppDataGrid<OrganizationalUnitAdmin>(
                  items: state.list,
                  isLoading: isLoading,
                  emptyMessage: 'No se encontraron registros con ese criterio.',
                  columns: unitsTableColumns(),
                  actions: canManage
                      ? [
                          AppDataGridAction<OrganizationalUnitAdmin>(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar',
                            onPressed: (item) {
                              cubit.changeSelected(item);
                              showDialog<void>(
                                context: context,
                                builder: (dialogContext) {
                                  return BlocProvider.value(
                                    value: BlocProvider.of<UnitsCubit>(context),
                                    child: UpsertUnitsPage(
                                      typeOperation: TypeOperation.update,
                                      hostDialogContext: dialogContext,
                                      ownerContext: context,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          AppDataGridAction<OrganizationalUnitAdmin>(
                            icon: Icons.toggle_on_outlined,
                            tooltip: 'Desactivar',
                            visibleWhen: (item) => item.isActive,
                            onPressed: cubit.toggleActive,
                          ),
                          AppDataGridAction<OrganizationalUnitAdmin>(
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
