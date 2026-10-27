import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondenceDetailHeader extends StatelessWidget {
  const CorrespondenceDetailHeader({
    required this.item,
    required this.onBack,
    this.onDerive,
    super.key,
  });

  final CorrespondenceEntity item;
  final VoidCallback onBack;
  final VoidCallback? onDerive;

  static const _compactMaxWidth = 767.0;

  @override
  Widget build(BuildContext context) {
    final showChainingPdf =
        item.hasDocumentPdf || supportsEncadenamientoPdf(item.documentTypeCode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth <= _compactMaxWidth;
        const chainingLabel = 'Ver PDF';
        final subtitle = item.cite.isNotEmpty ? item.cite : item.routeNumber;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle de correspondencia',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: isCompact ? 20 : 24,
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
                            .openChainingPdf(operational: item.hasDocumentPdf),
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

        final actions = Wrap(spacing: 8, runSpacing: 8, children: [
          if (chainingButton != null) chainingButton,
          if (showChainingPdf)
            BlocBuilder<CorrespondenceDocumentActionsCubit,
                CorrespondenceDocumentActionsState>(
              builder: (context, state) => OutlinedButton.icon(
                onPressed: state.openingChainingPdf
                    ? null
                    : () => context
                        .read<CorrespondenceDocumentActionsCubit>()
                        .downloadChainingPdf(operational: item.hasDocumentPdf),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Descargar PDF'),
              ),
            ),
          if (onDerive != null)
            FilledButton.icon(
                onPressed: onDerive,
                icon: const Icon(Icons.forward_rounded),
                label: const Text('Derivar trámite')),
        ]);
        if (constraints.maxWidth >= 1100) {
          return Row(children: [
            _BackButton(onBack: onBack),
            const SizedBox(width: 16),
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            actions,
          ]);
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (isCompact)
                  IconButton(
                      tooltip: 'Volver',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded))
                else
                  _BackButton(onBack: onBack),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(child: titleBlock),
              ]),
              if (showChainingPdf || onDerive != null) ...[
                const SizedBox(height: 12),
                Align(
                    alignment: isCompact
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: actions),
              ],
            ]);
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
