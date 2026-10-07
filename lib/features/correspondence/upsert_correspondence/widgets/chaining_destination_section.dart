import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/destination_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:flutter/material.dart';

/// Destinos de encadenamiento: primer destinatario fijo (alcalde) + segundo seleccionable.
class ChainingDestinationSection extends StatelessWidget {
  const ChainingDestinationSection({
    required this.institutionalMayor,
    required this.organizationalUnits,
    required this.unitUsers,
    required this.unitUsersLoading,
    this.errorMessage,
    super.key,
  });

  final InstitutionalMayor? institutionalMayor;
  final String? errorMessage;
  final List<OrganizationalUnit> organizationalUnits;
  final List<UnitUser> unitUsers;
  final bool unitUsersLoading;

  @override
  Widget build(BuildContext context) {
    final mayor = institutionalMayor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UpsertFormSection(
          title: 'Primer destinatario',
          child: mayor == null
              ? Text(
                  errorMessage ??
                      'No se pudo cargar el titular ejecutivo municipal (Alcalde/Alcaldesa).',
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: UiColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: UiColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mayor.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mayor.positionName} · ${mayor.unitName}',
                        style: const TextStyle(
                          color: UiColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PARA: ${mayor.paraLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: UiColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        DestinationSection(
          sectionTitle: 'Segundo destinatario',
          organizationalUnits: organizationalUnits,
          unitUsers: unitUsers,
          unitUsersLoading: unitUsersLoading,
          requireSpecificUser: true,
        ),
      ],
    );
  }
}
