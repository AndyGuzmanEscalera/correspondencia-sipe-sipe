import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondenceDetailHeader extends StatelessWidget {
  const CorrespondenceDetailHeader({
    required this.item,
    required this.onBack,
    super.key,
  });

  final CorrespondenceEntity item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final showChainingPdf =
        supportsEncadenamientoPdf(item.documentTypeCode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final chainingLabel = constraints.maxWidth <= 767
            ? 'Encadenamiento'
            : 'Ver encadenamiento';

        return SectionHeader(
          title: 'Detalle de correspondencia',
          subtitle: item.cite.isNotEmpty ? item.cite : item.routeNumber,
          actions: [
            if (showChainingPdf)
              BlocBuilder<CorrespondenceDocumentActionsCubit,
                  CorrespondenceDocumentActionsState>(
                builder: (context, state) {
                  return OutlinedButton.icon(
                    onPressed: state.openingChainingPdf
                        ? null
                        : () => context
                            .read<CorrespondenceDocumentActionsCubit>()
                            .openChainingPdf(),
                    icon: state.openingChainingPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(
                      state.openingChainingPdf ? 'Abriendo...' : chainingLabel,
                    ),
                  );
                },
              ),
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Volver'),
            ),
          ],
        );
      },
    );
  }
}
