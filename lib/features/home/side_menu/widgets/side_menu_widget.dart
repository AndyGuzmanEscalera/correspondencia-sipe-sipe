import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SideMenuWidget extends StatelessWidget {
  const SideMenuWidget({
    this.onItemSelected,
    super.key,
  });

  final VoidCallback? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: UiColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: UiColors.primary.withOpacity(0.15),
                    borderRadius: AppDecorations.borderRadiusMd,
                    border:
                        Border.all(color: UiColors.primary.withOpacity(0.35)),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: UiColors.primaryMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GAM SIPE SIPE',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: UiColors.textOnDark,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Correspondencia',
                        style: TextStyle(
                          color: UiColors.textOnDarkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Color(0xFF1E293B), height: 1),
          ),
          Expanded(
            child: BlocBuilder<SideMenuCubit, SideMenuState>(
              builder: (context, state) {
                return Scrollbar(
                  child: ListView(
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
                              onItemSelected?.call();
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
}
