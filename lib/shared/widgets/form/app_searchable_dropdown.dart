import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/validator_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_form_field_style.dart';
import 'package:flutter/material.dart';

/// Dropdown con búsqueda local sobre [items] ya cargados (sin requests por tecla).
class AppSearchableDropdown<T> extends StatefulWidget {
  const AppSearchableDropdown({
    required this.controller,
    required this.items,
    required this.label,
    super.key,
    this.hint = 'Seleccione una opción',
    this.searchHint = 'Buscar...',
    this.emptyItemsMessage = 'No hay opciones disponibles.',
    this.emptySearchMessage = 'No se encontraron resultados.',
    this.validators,
    this.onChanged,
    this.matchesQuery,
  });

  final ControllerFieldDropdown<T> controller;
  final List<FormOption<T>> items;
  final String label;
  final String hint;
  final String searchHint;
  final String emptyItemsMessage;
  final String emptySearchMessage;
  final List<AbstractValid>? validators;
  final void Function(FormOption<T>)? onChanged;
  final bool Function(FormOption<T> item, String query)? matchesQuery;

  @override
  State<AppSearchableDropdown<T>> createState() =>
      _AppSearchableDropdownState<T>();
}

class _AppSearchableDropdownState<T> extends State<AppSearchableDropdown<T>> {
  String? _validate(FormOption<T>? value) {
    if (widget.validators == null || widget.validators!.isEmpty) return null;
    final text = value?.text ?? '';
    return Validator.validation(text, widget.validators!);
  }

  bool _defaultMatch(FormOption<T> item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (item.text.toLowerCase().contains(q)) return true;
    final description = item.description;
    if (description != null && description.toLowerCase().contains(q)) {
      return true;
    }
    final keywords = item.keywords;
    if (keywords != null) {
      for (final keyword in keywords) {
        if (keyword.toLowerCase().contains(q)) return true;
      }
    }
    return false;
  }

  Future<void> _openPicker() async {
    if (widget.items.isEmpty) return;

    final selected = await showModalBottomSheet<FormOption<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _SearchablePickerSheet<T>(
          items: widget.items,
          searchHint: widget.searchHint,
          emptyItemsMessage: widget.emptyItemsMessage,
          emptySearchMessage: widget.emptySearchMessage,
          matchesQuery: widget.matchesQuery ?? _defaultMatch,
          initialSelection: widget.controller.isExist()
              ? widget.controller.value
              : null,
        );
      },
    );

    if (selected == null) return;
    widget.controller.setValue(selected);
    widget.onChanged?.call(selected);
    widget.controller.fieldKey.currentState?.didChange(selected);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selected =
        widget.controller.isExist() ? widget.controller.value : null;
    final displayText = selected?.text ?? widget.hint;
    final hasSelection = selected != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: FormField<FormOption<T>>(
        key: widget.controller.fieldKey,
        validator: _validate,
        initialValue: selected,
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.items.isEmpty ? null : _openPicker,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: AppFormFieldStyle.dropdownDecoration(
                    label: widget.label,
                  ).copyWith(
                    errorText: field.errorText,
                    suffixIcon: const Icon(Icons.search_rounded),
                  ),
                  child: Text(
                    hasSelection ? displayText : widget.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFormFieldStyle.fieldText.copyWith(
                      color: hasSelection
                          ? AppFormFieldStyle.fieldText.color
                          : AppFormFieldStyle.fieldText.color?.withOpacity(0.55),
                      fontWeight:
                          hasSelection ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (widget.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    widget.emptyItemsMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  const _SearchablePickerSheet({
    required this.items,
    required this.searchHint,
    required this.emptyItemsMessage,
    required this.emptySearchMessage,
    required this.matchesQuery,
    this.initialSelection,
  });

  final List<FormOption<T>> items;
  final String searchHint;
  final String emptyItemsMessage;
  final String emptySearchMessage;
  final bool Function(FormOption<T> item, String query) matchesQuery;
  final FormOption<T>? initialSelection;

  @override
  State<_SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((item) => widget.matchesQuery(item, _query))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Material(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: widget.items.isEmpty
                    ? Center(child: Text(widget.emptyItemsMessage))
                    : filtered.isEmpty
                        ? Center(child: Text(widget.emptySearchMessage))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final isSelected =
                                  widget.initialSelection?.value == item.value;
                              return ListTile(
                                selected: isSelected,
                                title: Text(
                                  item.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: item.description == null ||
                                        item.description!.isEmpty
                                    ? null
                                    : Text(
                                        item.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                onTap: () => Navigator.of(context).pop(item),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
