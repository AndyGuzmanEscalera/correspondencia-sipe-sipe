import 'package:flutter/material.dart';

enum _Status { active, inactive, all }

class AdminActiveFilter extends StatefulWidget {
  const AdminActiveFilter({required this.onChanged, super.key});
  final ValueChanged<bool?> onChanged;
  @override
  State<AdminActiveFilter> createState() => _AdminActiveFilterState();
}

class _AdminActiveFilterState extends State<AdminActiveFilter> {
  _Status _value = _Status.active;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: DropdownButtonFormField<_Status>(
          value: _value,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: const [
            DropdownMenuItem(value: _Status.active, child: Text('Activos')),
            DropdownMenuItem(value: _Status.inactive, child: Text('Inactivos')),
            DropdownMenuItem(value: _Status.all, child: Text('Todos')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _value = value);
            widget.onChanged(switch (value) {
              _Status.active => true,
              _Status.inactive => false,
              _Status.all => null
            });
          },
        ),
      );
}
