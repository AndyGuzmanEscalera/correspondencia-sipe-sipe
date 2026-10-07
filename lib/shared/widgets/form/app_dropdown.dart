import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/validator_field.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_form_field_style.dart';
import 'package:flutter/material.dart';

/// Dropdown con buscador integrado (patrón Inventario `DropdownCustomPro`).
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    required this.controller,
    required this.items,
    required this.label,
    super.key,
    this.title,
    this.hint = 'Seleccione una opción',
    this.searchHint = 'Buscar...',
    this.emptyItemsMessage = 'No hay opciones disponibles.',
    this.emptySearchMessage = 'No se encontraron resultados.',
    this.validators,
    this.onChanged,
    this.matchesQuery,
    this.enabled = true,
  });

  final ControllerFieldDropdown<T> controller;
  final List<FormOption<T>> items;
  final String label;
  final String? title;
  final String hint;
  final String searchHint;
  final String emptyItemsMessage;
  final String emptySearchMessage;
  final List<AbstractValid>? validators;
  final void Function(FormOption<T>)? onChanged;
  final bool Function(FormOption<T> item, String query)? matchesQuery;
  final bool enabled;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  String? _validate(FormOption<T>? value) {
    if (widget.validators == null || widget.validators!.isEmpty) return null;
    final text =
        widget.controller.isExist() ? widget.controller.value.text : '';
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
    if (!widget.enabled || widget.items.isEmpty) return;

    final selected = await showModalBottomSheet<FormOption<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SearchableDropdownPickerSheet<T>(
          items: widget.items,
          searchHint: widget.searchHint,
          emptyItemsMessage: widget.emptyItemsMessage,
          emptySearchMessage: widget.emptySearchMessage,
          matchesQuery: widget.matchesQuery ?? _defaultMatch,
          initialSelection:
              widget.controller.isExist() ? widget.controller.value : null,
        );
      },
    );

    if (!mounted || selected == null) return;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            Text(widget.title!, style: AppFormFieldStyle.title),
            const SizedBox(height: 8),
          ],
          FormField<FormOption<T>>(
            key: widget.controller.fieldKey,
            validator: _validate,
            initialValue: selected,
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: !widget.enabled || widget.items.isEmpty
                        ? null
                        : _openPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: AppFormFieldStyle.dropdownDecoration(
                        label: widget.label,
                      ).copyWith(
                        enabled: widget.enabled,
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
                              : AppFormFieldStyle.fieldText.color
                                  ?.withOpacity(0.55),
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
        ],
      ),
    );
  }
}

/// Hoja modal reutilizable para listas filtrables (dropdowns con buscador).
class SearchableDropdownPickerSheet<T> extends StatefulWidget {
  const SearchableDropdownPickerSheet({
    required this.items,
    required this.searchHint,
    required this.emptyItemsMessage,
    required this.emptySearchMessage,
    required this.matchesQuery,
    this.initialSelection,
    super.key,
  });

  final List<FormOption<T>> items;
  final String searchHint;
  final String emptyItemsMessage;
  final String emptySearchMessage;
  final bool Function(FormOption<T> item, String query) matchesQuery;
  final FormOption<T>? initialSelection;

  @override
  State<SearchableDropdownPickerSheet<T>> createState() =>
      _SearchableDropdownPickerSheetState<T>();
}

class _SearchableDropdownPickerSheetState<T>
    extends State<SearchableDropdownPickerSheet<T>> {
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
                  autofocus: true,
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
                                  style: AppFormFieldStyle.fieldText.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
