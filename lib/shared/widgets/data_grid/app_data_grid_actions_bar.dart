import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:flutter/material.dart';

class AppDataGridActionsBar<T> extends StatelessWidget {
  const AppDataGridActionsBar({
    required this.item,
    required this.actions,
    this.compact = false,
    this.iconButtonSize = 36,
    super.key,
  });

  final T item;
  final List<AppDataGridAction<T>> actions;
  final bool compact;
  final double iconButtonSize;

  @override
  Widget build(BuildContext context) {
    final visible = actions.where((action) => action.isVisible(item)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final maxInline = compact ? 1 : 2;
    if (visible.length <= maxInline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: visible
            .map(
              (action) => _ActionIconButton(
                action: action,
                item: item,
                size: iconButtonSize,
              ),
            )
            .toList(),
      );
    }

    return PopupMenuButton<int>(
      tooltip: 'Acciones',
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: UiColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: iconButtonSize,
        minHeight: iconButtonSize,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: UiColors.borderLight),
      ),
      elevation: 3,
      itemBuilder: (context) {
        return visible
            .asMap()
            .entries
            .map(
              (entry) {
                final isEnabled = entry.value.isEnabled(item);
                final color = isEnabled
                    ? (entry.value.color ?? UiColors.textPrimary)
                    : UiColors.textMuted;
                return PopupMenuItem<int>(
                  value: entry.key,
                  enabled: isEnabled,
                  child: Row(
                    children: [
                      Icon(entry.value.icon, size: 18, color: color),
                      const SizedBox(width: 10),
                      Text(
                        entry.value.tooltip,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isEnabled
                              ? UiColors.textPrimary
                              : UiColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
            .toList();
      },
      onSelected: (index) {
        final action = visible[index];
        if (action.isEnabled(item)) action.onPressed(item);
      },
    );
  }
}

class _ActionIconButton<T> extends StatelessWidget {
  const _ActionIconButton({
    required this.action,
    required this.item,
    required this.size,
  });

  final AppDataGridAction<T> action;
  final T item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = action.isEnabled(item);
    final color = enabled
        ? (action.color ?? UiColors.textSecondary)
        : UiColors.textMuted;

    return IconButton(
      tooltip: action.tooltip,
      onPressed: enabled ? () => action.onPressed(item) : null,
      icon: Icon(action.icon, size: 19, color: color),
      splashRadius: size / 2,
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: EdgeInsets.zero,
    );
  }
}
