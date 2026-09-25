import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_page.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/tables/correspondence_table.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/sent_entry_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SentEntryBody extends StatelessWidget {
  const SentEntryBody({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SentEntryCubit>();

    return AdminContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Enviados',
            subtitle: 'Correspondencias iniciadas o derivadas por usted',
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                onPressed: () async {
                  await cubit.refresh();
                  if (context.mounted) {
                    _refreshSideMenuBadges(context);
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SearchField(
            hint: 'Buscar por CITE, asunto, referencia o hoja de ruta',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          BlocBuilder<SentEntryCubit, SentEntryState>(
            builder: (context, state) {
              final isLoading =
                  state.generalStatus == GeneralStatus.loading &&
                      state.items.isEmpty;

              return DataPanel(
                child: AppDataGrid<CorrespondenceEntity>(
                  items: state.items,
                  isLoading: isLoading,
                  emptyMessage: _emptyMessage(query: state.query),
                  onRowTap: (item) => _openDetail(context, item),
                  columns: sentCorrespondenceTableColumns(),
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

  String _emptyMessage({required String query}) {
    if (query.trim().isNotEmpty) {
      return 'No se encontraron correspondencias enviadas con ese criterio.';
    }
    return 'No tiene correspondencias enviadas.';
  }

  Future<void> _openDetail(BuildContext context, CorrespondenceEntity item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CorrespondenceDetailPage(correspondenceId: item.id),
      ),
    );
    if (!context.mounted) return;
    await context.read<SentEntryCubit>().refresh();
    if (!context.mounted) return;
    _refreshSideMenuBadges(context);
  }

  void _refreshSideMenuBadges(BuildContext context) {
    final permissions =
        context.read<AppSessionCubit>().state.userSession?.permissions ?? [];
    context.read<SideMenuCubit>().refreshBadges(permissions: permissions);
  }
}
