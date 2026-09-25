import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:flutter/material.dart';

class OriginSection extends StatelessWidget {
  const OriginSection({
    required this.profile,
    required this.employees,
    required this.isExternal,
    required this.onTypeChanged,
    super.key,
  });

  final DocumentFormProfile profile;
  final List<EmployeeOption> employees;
  final bool isExternal;
  final ValueChanged<CorrespondenceTypeCode> onTypeChanged;

  bool get _showsCorrespondenceType =>
      profile == DocumentFormProfile.chaining ||
      profile == DocumentFormProfile.generic;

  bool get _showsExternalFields =>
      isExternal &&
      (profile == DocumentFormProfile.chaining ||
          profile == DocumentFormProfile.generic);

  bool get _showsEmployeeOrigin =>
      profile == DocumentFormProfile.technicalReport ||
      profile == DocumentFormProfile.internalNote ||
      (profile == DocumentFormProfile.chaining && !isExternal) ||
      (profile == DocumentFormProfile.generic && !isExternal);

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);
    final employeeItems = employees
        .map(
          (employee) => FormOption<String>(
            id: employee.id.hashCode,
            text: employee.unitName != null
                ? '${employee.fullName} (${employee.unitName})'
                : employee.fullName,
            value: employee.id,
          ),
        )
        .toList();

    return UpsertFormSection(
      title: 'Origen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showsCorrespondenceType)
          AppDropdown<CorrespondenceTypeCode>(
            controller: inherited.type,
            label: 'Tipo de correspondencia',
            items: UpsertCorrespondenceInherited.typeItems,
            onChanged: (option) {
              onTypeChanged(option.value!);
            },
          ),
        if (_showsEmployeeOrigin) ...[
          if (employeeItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No hay empleados activos disponibles.'),
            )
          else
            AppDropdown<String>(
              controller: inherited.originEmployee,
              label: 'Empleado origen',
              items: employeeItems,
              validators: [
                RequiredValid(error: 'Seleccione el empleado origen'),
              ],
            ),
        ],
        if (_showsExternalFields) ...[
          AppTextField(
            controller: inherited.senderName,
            label: 'Remitente externo',
            validators: [
              RequiredValid(error: 'Campo requerido'),
            ],
          ),
          AppTextField(
            controller: inherited.senderDocument,
            label: 'Documento del remitente (opcional)',
          ),
          AppTextField(
            controller: inherited.senderContact,
            label: 'Contacto del remitente (opcional)',
            inputType: TextInputType.phone,
          ),
          AppTextField(
            controller: inherited.originDescription,
            label: 'Descripción del origen (opcional)',
          ),
        ],
        ],
      ),
    );
  }
}
