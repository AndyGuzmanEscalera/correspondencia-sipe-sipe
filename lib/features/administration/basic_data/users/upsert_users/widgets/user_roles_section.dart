import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/helpers/upsert_users_inherited.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:flutter/material.dart';

class UserRolesSection extends StatefulWidget {
  const UserRolesSection({
    required this.roles,
    super.key,
  });

  final List<RoleOption> roles;

  @override
  State<UserRolesSection> createState() => _UserRolesSectionState();
}

class _UserRolesSectionState extends State<UserRolesSection> {
  @override
  Widget build(BuildContext context) {
    final inherited = UpsertUsersInherited.of(context);
    final roleItems = widget.roles
        .map(
          (role) => FormOption<String>(
            id: role.id.hashCode,
            text: role.name,
            value: role.id,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDropdown<String>(
          controller: inherited.rolePicker,
          label: 'Agregar rol',
          items: roleItems,
          onChanged: (option) {
            setState(() => inherited.addRole(option.value!));
          },
        ),
        if (inherited.selectedRoleIds.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: inherited.selectedRoleIds.map((roleId) {
              final role = widget.roles.firstWhere(
                (item) => item.id == roleId,
              );
              return Chip(
                label: Text(role.name),
                onDeleted: () {
                  setState(() => inherited.removeRole(roleId));
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}
