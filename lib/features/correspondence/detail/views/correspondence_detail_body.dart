import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_device.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_derive_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_detail_header.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_info_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_movements_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Composición vertical del detalle.
///
/// Futuros módulos (Adjuntos, Documentos generados) se insertan como widgets
/// hermanos entre info y movimientos, o bajo tabs cuando el volumen lo exija.
class CorrespondenceDetailBody extends StatelessWidget {
  const CorrespondenceDetailBody({
    required this.correspondenceId,
    super.key,
  });

  final String correspondenceId;

  @override
  Widget build(BuildContext context) {
    final padding = context.isSmallScreen ? 16.0 : 32.0;

    return Container(
      color: UiColors.background,
      padding: EdgeInsets.fromLTRB(padding, padding - 4, padding, padding),
      child: BlocBuilder<CorrespondenceDetailCubit, CorrespondenceDetailState>(
        builder: (context, state) {
          final item = state.correspondence;
          if (item == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CorrespondenceDetailHeader(
                item: item,
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              CorrespondenceInfoSection(item: item),
              const SizedBox(height: 24),
              // Slot futuro: CorrespondenceAttachmentsSection
              // Slot futuro: CorrespondenceGeneratedDocumentsSection
              Expanded(
                child: CorrespondenceMovementsSection(
                  movements: state.movements,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: CorrespondenceDeriveSection(
                  correspondenceId: correspondenceId,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
