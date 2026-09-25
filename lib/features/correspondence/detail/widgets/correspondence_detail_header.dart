import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
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

  static const _compactMaxWidth = 767.0;

  @override
  Widget build(BuildContext context) {
    final showChainingPdf =
        supportsEncadenamientoPdf(item.documentTypeCode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth <= _compactMaxWidth;
        final chainingLabel = isCompact ? 'Encadenamiento' : 'Ver encadenamiento';
        final subtitle = item.cite.isNotEmpty ? item.cite : item.routeNumber;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle de correspondencia',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        );

        final chainingButton = showChainingPdf
            ? BlocBuilder<CorrespondenceDocumentActionsCubit,
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
              )
            : null;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onBack: onBack),
                  const SizedBox(width: 12),
                  Expanded(child: titleBlock),
                ],
              ),
              if (chainingButton != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: chainingButton,
                ),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackButton(onBack: onBack),
            const SizedBox(width: 16),
            Expanded(child: titleBlock),
            if (chainingButton != null) chainingButton,
          ],
        );
      },
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back_rounded),
      label: const Text('Volver'),
    );
  }
}
