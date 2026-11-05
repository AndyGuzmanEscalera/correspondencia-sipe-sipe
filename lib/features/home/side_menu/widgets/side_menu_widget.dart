import 'package:correspondencia_sipe_sipe/shared/widgets/official_logo.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SideMenuWidget extends StatefulWidget {
  const SideMenuWidget({
    this.onItemSelected,
    super.key,
  });

  final VoidCallback? onItemSelected;

  @override
  State<SideMenuWidget> createState() => _SideMenuWidgetState();
}

class _SideMenuWidgetState extends State<SideMenuWidget> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: UiColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OfficialLogo(white: true, width: 232),
                    SizedBox(height: 10),
                    Text('Correspondencia',
                        style: TextStyle(
                            color: UiColors.textOnDark, fontSize: 12)),
                  ])),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Color(0xFF1E293B), height: 1),
          ),
          Builder(builder: (context) {
            AppSessionCubit? sessionCubit;
            try {
              sessionCubit = context.read<AppSessionCubit>();
            } on ProviderNotFoundException {
              return const SizedBox.shrink();
            }
            return BlocBuilder<AppSessionCubit, AppSessionState>(
              bloc: sessionCubit,
              builder: (context, session) {
                final permissions =
                    session.userSession?.permissions ?? const [];
                if (!canCreateCorrespondence(permissions)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: FilledButton.icon(
                    onPressed: () => _openCreate(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva correspondencia'),
                  ),
                );
              },
            );
          }),
          Expanded(
            child: BlocBuilder<SideMenuCubit, SideMenuState>(
              builder: (context, state) {
                return Scrollbar(
                  controller: _scrollController,
                  child: ListView(
                    controller: _scrollController,
                    primary: false,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                    children: state.menus.map((item) {
                      if (item.isSection) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          child: Text(
                            item.title.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: UiColors.textOnDarkMuted,
                              letterSpacing: 1.1,
                            ),
                          ),
                        );
                      }

                      final selected = state.selected == item;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.read<SideMenuCubit>().select(item);
                              widget.onItemSelected?.call();
                            },
                            borderRadius: AppDecorations.borderRadiusSm,
                            hoverColor: UiColors.sidebarHover,
                            child: Ink(
                              decoration: AppDecorations.sidebarItem(
                                  selected: selected),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: 19,
                                      color: selected
                                          ? UiColors.primaryMuted
                                          : UiColors.textOnDarkMuted,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: selected
                                              ? UiColors.textOnDark
                                              : UiColors.textOnDarkMuted,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                    if (item.badge != null)
                                      Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 18,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? UiColors.primary
                                              : const Color(0xFF334155),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${item.badge}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final listCubit = getIt<CorrespondenceCubit>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: listCubit,
        child: UpsertCorrespondencePage(
          typeOperation: TypeOperation.create,
          hostDialogContext: dialogContext,
          ownerContext: context,
        ),
      ),
    );
    await listCubit.close();
  }
}
