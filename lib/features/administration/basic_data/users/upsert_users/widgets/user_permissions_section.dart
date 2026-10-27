import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:flutter/material.dart';
import '../helpers/upsert_users_inherited.dart';

class UserPermissionsSection extends StatefulWidget {
  const UserPermissionsSection(
      {required this.permissions,
      required this.canManage,
      this.directCodes = const [],
      this.effectiveCodes = const [],
      super.key});
  final List<PermissionOption> permissions;
  final bool canManage;
  final List<String> directCodes;
  final List<String> effectiveCodes;
  @override
  State<UserPermissionsSection> createState() => _UserPermissionsSectionState();
}

class _UserPermissionsSectionState extends State<UserPermissionsSection> {
  @override
  Widget build(BuildContext context) {
    final form = UpsertUsersInherited.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      const Text('Permisos directos',
          style: TextStyle(fontWeight: FontWeight.w700)),
      if (!widget.canManage && widget.permissions.isEmpty)
        Text(widget.directCodes.isEmpty
            ? 'Sin permisos directos'
            : widget.directCodes.join(', ')),
      for (final category in [
        'Administración',
        'Correspondencia - Lectura',
        'Correspondencia - Creación',
        'Correspondencia - Operación',
        'Reportes',
        'Configuración',
        'Otros'
      ])
        if (widget.permissions.any((p) => p.category == category))
          ExpansionTile(
              title: Text(category),
              initiallyExpanded: false,
              children: widget.permissions
                  .where((p) => p.category == category)
                  .map((p) => CheckboxListTile(
                        title: Text(p.description ?? p.code),
                        subtitle: Text(p.isDeprecated
                            ? '${p.code} · Legado: use los permisos específicos de creación'
                            : p.code),
                        value: form.selectedPermissionIds.contains(p.id),
                        onChanged: !widget.canManage
                            ? null
                            : (checked) => setState(() {
                                  if (checked == true) {
                                    form.selectedPermissionIds.add(p.id);
                                  } else {
                                    form.selectedPermissionIds.remove(p.id);
                                  }
                                }),
                      ))
                  .toList()),
      if (widget.effectiveCodes.isNotEmpty)
        ExpansionTile(
            title: const Text('Permisos efectivos actuales'),
            children: widget.effectiveCodes
                .map((code) => ListTile(dense: true, title: Text(code)))
                .toList()),
    ]);
  }
}
