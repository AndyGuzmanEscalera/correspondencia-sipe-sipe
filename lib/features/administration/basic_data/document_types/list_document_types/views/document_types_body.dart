import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/cubit/document_types_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/tables/document_types_table.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/upsert_document_types/views/upsert_document_types_view.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentTypesBody extends StatelessWidget {
  const DocumentTypesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionCubit>().state.userSession;
    final canManage = hasPermission(session, Permissions.documentTypesManage);
    final cubit = context.read<DocumentTypesCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Tipos de documento',
            subtitle: 'Catálogo institucional de tipos documentales',
            actions: [
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) {
                        return BlocProvider.value(
                          value: BlocProvider.of<DocumentTypesCubit>(context),
                          child: const UpsertDocumentTypesPage(
                            typeOperation: TypeOperation.create,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo tipo'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar por código o nombre',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          BlocBuilder<DocumentTypesCubit, DocumentTypesState>(
            builder: (context, state) {
              final isLoading = state.generalStatus == GeneralStatus.loading &&
                  state.list.isEmpty;
              return DataPanel(
                child: AppDataGrid<DocumentTypeAdmin>(
                  items: state.list,
                  isLoading: isLoading,
                  emptyMessage: 'No se encontraron registros con ese criterio.',
                  columns: documentTypesTableColumns(),
                  actions: canManage
                      ? [
                          AppDataGridAction<DocumentTypeAdmin>(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar',
                            onPressed: (item) {
                              cubit.changeSelected(item);
                              showDialog<void>(
                                context: context,
                                builder: (_) {
                                  return BlocProvider.value(
                                    value: BlocProvider.of<DocumentTypesCubit>(
                                      context,
                                    ),
                                    child: const UpsertDocumentTypesPage(
                                      typeOperation: TypeOperation.update,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          AppDataGridAction<DocumentTypeAdmin>(
                            icon: Icons.toggle_on_outlined,
                            tooltip: 'Desactivar',
                            visibleWhen: (item) => item.isActive,
                            onPressed: cubit.toggleActive,
                          ),
                          AppDataGridAction<DocumentTypeAdmin>(
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
