import 'dart:math' as math;

import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_desktop_table.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_mobile_item.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_pagination.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_value_utils.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Breakpoints for table vs cards. Uses [LayoutBuilder] width, not duplicate
/// responsive_framework logic elsewhere in the app.
class AppDataGridBreakpoints {
  AppDataGridBreakpoints._();

  static const mobileMax = 600.0;
  static const tabletMax = 900.0;

  static bool isMobile(double width) => width < mobileMax;
  static bool isTablet(double width) =>
      width >= mobileMax && width < tabletMax;
  static bool isDesktop(double width) => width >= tabletMax;
}

class AppDataGrid<T> extends StatefulWidget {
  const AppDataGrid({
    required this.items,
    required this.columns,
    this.actions = const [],
    this.isLoading = false,
    this.emptyMessage = 'No hay registros.',
    this.emptyWidget,
    this.onRowTap,
    this.onRowDoubleTap,
    this.mobileItemBuilder,
    this.rowActionsBuilder,
    this.allowSorting = true,
    this.onSortChanged,
    this.currentPage,
    this.pageSize,
    this.totalItems,
    this.totalPages,
    this.onPageChanged,
    this.onPageSizeChanged,
    this.nullLabel = AppDataGridValueUtils.defaultNullLabel,
    this.shrinkWrap = false,
    super.key,
  });

  final List<T> items;
  final List<AppDataGridColumn<T>> columns;
  final List<AppDataGridAction<T>> actions;
  final bool isLoading;
  final String emptyMessage;
  final Widget? emptyWidget;
  final void Function(T item)? onRowTap;
  final void Function(T item)? onRowDoubleTap;
  final Widget Function(BuildContext context, T item)? mobileItemBuilder;
  final Widget Function(BuildContext context, T item)? rowActionsBuilder;
  final bool allowSorting;
  final void Function(String key, bool ascending)? onSortChanged;
  final int? currentPage;
  final int? pageSize;
  final int? totalItems;
  final int? totalPages;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final String nullLabel;
  final bool shrinkWrap;

  @override
  State<AppDataGrid<T>> createState() => _AppDataGridState<T>();
}

class _AppDataGridState<T> extends State<AppDataGrid<T>> {
  String? _sortColumnKey;
  bool _sortAscending = true;
  List<T>? _sortedItems;

  @override
  void didUpdateWidget(covariant AppDataGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.columns != widget.columns) {
      _sortedItems = null;
    }
  }

  List<T> get _displayItems {
    if (_sortColumnKey == null || widget.onSortChanged != null) {
      return widget.items;
    }
    _sortedItems ??= _sortLocally(widget.items, _sortColumnKey!, _sortAscending);
    return _sortedItems!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = AppDataGridBreakpoints.isMobile(width);

        if (widget.isLoading && widget.items.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(UiColors.primary),
              ),
            ),
          );
        }

        if (!widget.isLoading && widget.items.isEmpty) {
          return widget.emptyWidget ??
              EmptyState(
                title: 'Sin registros',
                message: widget.emptyMessage,
                icon: Icons.table_rows_outlined,
              );
        }

        final content = isMobile
            ? _MobileList<T>(
                items: _displayItems,
                columns: widget.columns,
                actions: widget.actions,
                nullLabel: widget.nullLabel,
                onRowTap: widget.onRowTap,
                onRowDoubleTap: widget.onRowDoubleTap,
                mobileItemBuilder: widget.mobileItemBuilder,
                shrinkWrap: widget.shrinkWrap,
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(
                    width,
                    AppDataGridDesktopTable.estimateMinWidth(
                      widget.columns,
                      widget.actions,
                      rowActionsBuilder: widget.rowActionsBuilder,
                    ),
                  ),
                  child: AppDataGridDesktopTable<T>(
                    items: _displayItems,
                    columns: widget.columns,
                    actions: widget.actions,
                    nullLabel: widget.nullLabel,
                    allowSorting: widget.allowSorting,
                    sortColumnKey: _sortColumnKey,
                    sortAscending: _sortAscending,
                    onSort: _handleSort,
                    onRowTap: widget.onRowTap,
                    onRowDoubleTap: widget.onRowDoubleTap,
                    rowActionsBuilder: widget.rowActionsBuilder,
                  ),
                ),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isLoading && widget.items.isNotEmpty)
              const LinearProgressIndicator(
                minHeight: 2.5,
                color: UiColors.primary,
                backgroundColor: UiColors.borderLight,
              ),
            if (widget.shrinkWrap)
              content
            else
              Expanded(child: content),
            if (_showPagination)
              AppDataGridPagination(
                currentPage: widget.currentPage!,
                pageSize: widget.pageSize!,
                totalItems: widget.totalItems!,
                totalPages: widget.totalPages!,
                onPageChanged: widget.onPageChanged!,
                onPageSizeChanged: widget.onPageSizeChanged,
                compact: isMobile,
              ),
          ],
        );
      },
    );
  }

  bool get _showPagination =>
      widget.currentPage != null &&
      widget.pageSize != null &&
      widget.totalItems != null &&
      widget.totalPages != null &&
      widget.onPageChanged != null;

  void _handleSort(String key, bool ascending) {
    if (widget.onSortChanged != null) {
      widget.onSortChanged!(key, ascending);
      return;
    }
    setState(() {
      _sortColumnKey = key;
      _sortAscending = ascending;
      _sortedItems = null;
    });
  }

  List<T> _sortLocally(List<T> source, String key, bool ascending) {
    final column = widget.columns.firstWhere((c) => c.key == key);
    final sorted = List<T>.from(source);
    sorted.sort((a, b) {
      final result = AppDataGridValueUtils.compareValues(
        type: column.type,
        left: column.value(a),
        right: column.value(b),
      );
      return ascending ? result : -result;
    });
    return sorted;
  }
}

class _MobileList<T> extends StatelessWidget {
  const _MobileList({
    required this.items,
    required this.columns,
    required this.actions,
    required this.nullLabel,
    this.onRowTap,
    this.onRowDoubleTap,
    this.mobileItemBuilder,
    this.shrinkWrap = false,
  });

  final List<T> items;
  final List<AppDataGridColumn<T>> columns;
  final List<AppDataGridAction<T>> actions;
  final String nullLabel;
  final void Function(T item)? onRowTap;
  final void Function(T item)? onRowDoubleTap;
  final Widget Function(BuildContext context, T item)? mobileItemBuilder;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return AppDataGridMobileItem<T>(
          item: item,
          columns: columns,
          actions: actions,
          nullLabel: nullLabel,
          onTap: onRowTap == null ? null : () => onRowTap!(item),
          onDoubleTap:
              onRowDoubleTap == null ? null : () => onRowDoubleTap!(item),
          customBuilder: mobileItemBuilder,
        );
      },
    );
  }
}
