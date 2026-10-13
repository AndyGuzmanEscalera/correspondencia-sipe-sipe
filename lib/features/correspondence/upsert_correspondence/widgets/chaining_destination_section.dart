import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:flutter/material.dart';

class ChainingDestinationSection extends StatelessWidget {
  const ChainingDestinationSection({
    required this.firstRecipients,
    required this.organizationalUnits,
    required this.unitUsers,
    required this.unitUsersLoading,
    this.errorMessage,
    super.key,
  });

  final List<InstitutionalMayor> firstRecipients;
  final String? errorMessage;
  final List<OrganizationalUnit> organizationalUnits;
  final List<UnitUser> unitUsers;
  final bool unitUsersLoading;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UpsertFormSection(
            title: 'Primer destinatario',
            child: firstRecipients.isEmpty
                ? Text(errorMessage?.isNotEmpty == true
                    ? errorMessage!
                    : 'No hay receptores iniciales configurados y activos. Revise Configuración institucional.')
                : AppDropdown<String>(
                    controller: UpsertCorrespondenceInherited.of(context)
                        .firstRecipient,
                    label: 'Receptor inicial',
                    searchHint: 'Buscar receptor inicial',
                    items: [
                      for (final item in firstRecipients)
                        FormOption<String>(
                          id: item.employeeId.hashCode,
                          value: item.employeeId,
                          text: item.employeeName,
                          description:
                              '${item.positionName} · ${item.unitName}',
                          keywords: [item.positionName, item.unitName],
                        )
                    ],
                    validators: [
                      RequiredValid(
                          error: 'Seleccione el primer destinatario EDIE')
                    ],
                  ),
          ),
          AppTextField(
              controller:
                  UpsertCorrespondenceInherited.of(context).initialInstruction,
              label: 'Instrucción inicial / proveído (opcional)'),
        ],
      );
}
