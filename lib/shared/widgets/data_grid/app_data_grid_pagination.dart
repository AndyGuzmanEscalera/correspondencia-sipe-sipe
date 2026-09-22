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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          '$totalItems registro${totalItems == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: UiColors.textSecondary,
              ),
        ),
      );
    }

    final canPrev = currentPage > 1;
    final canNext = currentPage < totalPages;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Row(
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Página anterior',
              enabled: canPrev,
              onPressed: () => onPageChanged(currentPage - 1),
            ),
            Expanded(
              child: Text(
                'Página $currentPage de ${totalPages == 0 ? 1 : totalPages}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Página siguiente',
              enabled: canNext,
              onPressed: () => onPageChanged(currentPage + 1),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Text(
            'Mostrando ${totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1}'
            '–${((currentPage - 1) * pageSize) + _visibleCount()} de $totalItems',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: UiColors.textSecondary,
                ),
          ),
          const Spacer(),
          if (onPageSizeChanged != null) ...[
            Text(
              'Por página',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: pageSize,
              underline: const SizedBox.shrink(),
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
            const SizedBox(width: 16),
          ],
          _NavButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Página anterior',
            enabled: canPrev,
            onPressed: () => onPageChanged(currentPage - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('Página $currentPage de ${totalPages == 0 ? 1 : totalPages}'),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Página siguiente',
            enabled: canNext,
            onPressed: () => onPageChanged(currentPage + 1),
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
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }
}
