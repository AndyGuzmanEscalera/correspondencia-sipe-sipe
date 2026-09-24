import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_page.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/tables/correspondence_table.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondenceBody extends StatelessWidget {
  const CorrespondenceBody({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CorrespondenceCubit>();

    return AdminContent(
      child: Column(
        children: [
          SectionHeader(
            title: 'Correspondencias',
            subtitle: 'Registro institucional de trámites',
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) {
                      return BlocProvider.value(
                        value: BlocProvider.of<CorrespondenceCubit>(context),
                        child: const UpsertCorrespondencePage(
                          typeOperation: TypeOperation.create,
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nueva correspondencia'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SearchField(
            hint: 'Buscar por CITE, asunto o hoja de ruta',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          BlocBuilder<CorrespondenceCubit, CorrespondenceState>(
            builder: (context, state) {
              final isLoading = state.generalStatus == GeneralStatus.loading &&
                  state.list.isEmpty;
              return DataPanel(
                child: AppDataGrid<CorrespondenceEntity>(
                  items: state.list,
                  isLoading: isLoading,
                  emptyMessage:
                      'No se encontraron trámites con ese criterio de búsqueda.',
                  onRowTap: (item) => _openDetail(context, item),
                  columns: correspondenceTableColumns(),
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

  void _openDetail(BuildContext context, CorrespondenceEntity item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CorrespondenceDetailPage(correspondenceId: item.id),
      ),
    );
  }
}
