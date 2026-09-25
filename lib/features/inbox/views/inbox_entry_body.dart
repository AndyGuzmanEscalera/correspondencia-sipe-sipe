import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_page.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/tables/correspondence_table.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/inbox_entry_cubit.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InboxEntryBody extends StatelessWidget {
  const InboxEntryBody({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InboxEntryCubit>();

    return AdminContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Bandeja de entrada',
            subtitle: 'Correspondencia asignada y pendiente en su unidad',
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
          BlocBuilder<InboxEntryCubit, InboxEntryState>(
            buildWhen: (previous, current) =>
                previous.scope != current.scope ||
                previous.counts != current.counts,
            builder: (context, state) {
              return _InboxScopeTabs(
                scope: state.scope,
                counts: state.counts,
                onScopeChanged: cubit.changeScope,
              );
            },
          ),
          const SizedBox(height: 16),
          SearchField(
            hint: 'Buscar por CITE, asunto, referencia o hoja de ruta',
            onChanged: cubit.filter,
          ),
          const SizedBox(height: 20),
          BlocBuilder<InboxEntryCubit, InboxEntryState>(
            builder: (context, state) {
              final isLoading =
                  state.generalStatus == GeneralStatus.loading &&
                      state.items.isEmpty;
              final lacksInstitutionalContext = context
                      .read<AppSessionCubit>()
                      .state
                      .userSession
                      ?.employeeId ==
                  null;

              return DataPanel(
                child: AppDataGrid<CorrespondenceEntity>(
                  items: state.items,
                  isLoading: isLoading,
                  emptyMessage: _emptyMessage(
                    scope: state.scope,
                    query: state.query,
                    lacksInstitutionalContext: lacksInstitutionalContext,
                  ),
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

  String _emptyMessage({
    required repo.InboxScope scope,
    required String query,
    required bool lacksInstitutionalContext,
  }) {
    if (query.trim().isNotEmpty) {
      return 'No se encontraron correspondencias con ese criterio.';
    }
    if (lacksInstitutionalContext) {
      return 'Su usuario no tiene una unidad organizacional asignada.';
    }
    if (scope == repo.InboxScope.mine) {
      return 'No tiene correspondencias asignadas directamente.';
    }
    return 'No hay correspondencias pendientes en su unidad.';
  }

  Future<void> _openDetail(BuildContext context, CorrespondenceEntity item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CorrespondenceDetailPage(correspondenceId: item.id),
      ),
    );
    if (!context.mounted) return;
    await context.read<InboxEntryCubit>().refresh();
    if (!context.mounted) return;
    _refreshSideMenuBadges(context);
  }

  void _refreshSideMenuBadges(BuildContext context) {
    final permissions =
        context.read<AppSessionCubit>().state.userSession?.permissions ?? [];
    context.read<SideMenuCubit>().refreshBadges(permissions: permissions);
  }
}

class _InboxScopeTabs extends StatelessWidget {
  const _InboxScopeTabs({
    required this.scope,
    required this.counts,
    required this.onScopeChanged,
  });

  final repo.InboxScope scope;
  final repo.InboxCounts counts;
  final ValueChanged<repo.InboxScope> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<repo.InboxScope>(
        segments: [
          ButtonSegment(
            value: repo.InboxScope.mine,
            label: Text('Asignados a mí (${counts.mine})'),
          ),
          ButtonSegment(
            value: repo.InboxScope.unit,
            label: Text('De mi unidad (${counts.unit})'),
          ),
        ],
        selected: {scope},
        onSelectionChanged: (selection) {
          onScopeChanged(selection.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return UiColors.primary;
            }
            return UiColors.textSecondary;
          }),
        ),
      ),
    );
  }
}
