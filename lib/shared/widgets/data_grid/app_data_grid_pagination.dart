import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

class AppDataGridPagination extends StatelessWidget {
  const AppDataGridPagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.onPageChanged,
    this.onPageSizeChanged,
    this.compact = false,
    super.key,
  });

  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1 && totalItems <= pageSize) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: UiColors.borderLight, width: 1.5),
          ),
        ),
        child: Text(
          '$totalItems registro${totalItems == 1 ? '' : 's'}',
          style: const TextStyle(
            fontSize: 12,
            color: UiColors.textSecondary,
          ),
        ),
      );
    }

    final canPrev = currentPage > 1;
    final canNext = currentPage < totalPages;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: UiColors.borderLight, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Página anterior',
              enabled: canPrev,
              onPressed: () => onPageChanged(currentPage - 1),
              size: 44,
              iconSize: 22,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Página $currentPage de ${totalPages == 0 ? 1 : totalPages}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: UiColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalItems registros',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: UiColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Página siguiente',
              enabled: canNext,
              onPressed: () => onPageChanged(currentPage + 1),
              size: 44,
              iconSize: 22,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: UiColors.borderLight, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Mostrando ${totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1}'
            '–${((currentPage - 1) * pageSize) + _visibleCount()} de $totalItems registros',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: UiColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (onPageSizeChanged != null) ...[
            const Text(
              'Por página:',
              style: TextStyle(
                fontSize: 12.5,
                color: UiColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: UiColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: UiColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: pageSize,
                  isDense: true,
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: UiColors.textSecondary,
                  ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: UiColors.textPrimary,
                  ),
                  items: const [10, 20, 50, 100]
                      .map(
                        (size) => DropdownMenuItem(
                          value: size,
                          child: Text('$size'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onPageSizeChanged!(value);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          _NavButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Página anterior',
            enabled: canPrev,
            onPressed: () => onPageChanged(currentPage - 1),
            size: 36,
            iconSize: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Página $currentPage de ${totalPages == 0 ? 1 : totalPages}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: UiColors.textPrimary,
              ),
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Página siguiente',
            enabled: canNext,
            onPressed: () => onPageChanged(currentPage + 1),
            size: 36,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  int _visibleCount() {
    if (totalItems == 0) return 0;
    final start = (currentPage - 1) * pageSize;
    final end = start + pageSize;
    return end > totalItems ? totalItems - start : pageSize;
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: iconSize),
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      splashRadius: size / 2,
      color: enabled ? UiColors.textPrimary : UiColors.textMuted,
    );
  }
}
