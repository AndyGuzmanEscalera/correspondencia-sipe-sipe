import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DestinationSection extends StatelessWidget {
  const DestinationSection({
    required this.organizationalUnits,
    required this.unitUsers,
    required this.unitUsersLoading,
    super.key,
  });

  final List<OrganizationalUnit> organizationalUnits;
  final List<UnitUser> unitUsers;
  final bool unitUsersLoading;

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);
    final upsertCubit = context.read<UpsertCorrespondenceCubit>();

    final unitItems = organizationalUnits
        .map(
          (unit) => FormOption<String>(
            id: unit.id.hashCode,
            text: unit.name,
            value: unit.id,
          ),
        )
        .toList();

    final userItems = [
      UpsertCorrespondenceInherited.noUserOption,
      ...unitUsers.map(
        (user) => FormOption<String>(
          id: user.id.hashCode,
          text: user.displayName,
          value: user.id,
        ),
      ),
    ];

    return UpsertFormSection(
      title: 'Destino e instrucción',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (unitItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No hay unidades organizacionales activas.'),
          )
        else
          AppDropdown<String>(
            controller: inherited.toUnit,
            label: 'Unidad destino',
            items: unitItems,
            validators: [
              RequiredValid(error: 'Seleccione una unidad destino'),
            ],
            onChanged: (option) {
              inherited.clearDestinationUser();
              upsertCubit.loadUnitUsers(option.value!);
            },
          ),
        if (inherited.toUnit.isExist()) ...[
          if (unitUsersLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          AppDropdown<String>(
            controller: inherited.toUser,
            label: 'Usuario destino (opcional)',
            items: userItems,
          ),
        ],
          AppTextField(
            controller: inherited.initialInstruction,
            label: 'Instrucción inicial / proveído (opcional)',
          ),
        ],
      ),
    );
  }
}
