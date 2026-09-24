import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/cubit/derive_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/helpers/derive_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeriveCorrespondenceFormSection extends StatelessWidget {
  const DeriveCorrespondenceFormSection({
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
    final inherited = DeriveCorrespondenceInherited.of(context);
    final deriveCubit = context.read<DeriveCorrespondenceCubit>();

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
      DeriveCorrespondenceInherited.noUserOption,
      ...unitUsers.map(
        (user) => FormOption<String>(
          id: user.id.hashCode,
          text: user.displayName,
          value: user.id,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unitItems.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'No hay unidades organizacionales activas disponibles.',
            ),
          )
        else
          AppDropdown<String>(
            controller: inherited.toUnit,
            label: 'Unidad destino',
            items: unitItems,
            validators: [
              RequiredValid(error: 'Seleccione una unidad'),
            ],
            onChanged: (option) {
              inherited.clearDestinationUser();
              deriveCubit.loadUnitUsers(option.value!);
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
          controller: inherited.instruction,
          label: 'Instrucción',
        ),
        AppTextField(
          controller: inherited.observation,
          label: 'Observación',
        ),
      ],
    );
  }
}
