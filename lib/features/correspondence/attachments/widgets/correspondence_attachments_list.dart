import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/platform/format_file_size.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/cubit/correspondence_attachments_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CorrespondenceAttachmentsList extends StatelessWidget {
  const CorrespondenceAttachmentsList({
    required this.attachments,
    required this.downloadingAttachmentId,
    required this.deactivatingAttachmentId,
    super.key,
  });

  final List<CorrespondenceAttachment> attachments;
  final String? downloadingAttachmentId;
  final String? deactivatingAttachmentId;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;

        return Column(
          children: attachments.map((attachment) {
            final isDownloading = downloadingAttachmentId == attachment.id;
            final isDeactivating = deactivatingAttachmentId == attachment.id;
            final filename = attachment.originalFilename ?? 'Archivo';
            final sizeLabel = formatFileSize(attachment.sizeBytes);
            final mimeLabel = attachment.mimeType ?? 'Tipo desconocido';
            final meta = [
              if (sizeLabel.isNotEmpty) sizeLabel,
              mimeLabel,
              dateFormat.format(attachment.createdAt),
              if (attachment.createdByUsername != null)
                attachment.createdByUsername,
            ].join(' · ');

            if (isCompact) {
              return _AttachmentCard(
                filename: filename,
                meta: meta,
                isDownloading: isDownloading,
                isDeactivating: isDeactivating,
                onDownload: () => _download(context, attachment),
                onDeactivate: () => _confirmDeactivate(context, attachment),
              );
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file),
              title: Text(filename),
              subtitle: Text(meta),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDownloading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      tooltip: 'Descargar',
                      icon: const Icon(Icons.download_outlined),
                      onPressed: () => _download(context, attachment),
                    ),
                  if (isDeactivating)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      tooltip: 'Quitar adjunto',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDeactivate(context, attachment),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _download(
    BuildContext context,
    CorrespondenceAttachment attachment,
  ) {
    return context.read<CorrespondenceAttachmentsCubit>().downloadAttachment(
          attachmentId: attachment.id,
          filename: attachment.originalFilename ?? 'archivo',
          mimeType: attachment.mimeType,
        );
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    CorrespondenceAttachment attachment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitar adjunto'),
        content: Text(
          '¿Desea quitar "${attachment.originalFilename ?? 'este archivo'}" '
          'de la correspondencia?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Quitar adjunto'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context
        .read<CorrespondenceAttachmentsCubit>()
        .deactivate(attachment.id);
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.filename,
    required this.meta,
    required this.isDownloading,
    required this.isDeactivating,
    required this.onDownload,
    required this.onDeactivate,
  });

  final String filename;
  final String meta;
  final bool isDownloading;
  final bool isDeactivating;
  final VoidCallback onDownload;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.attach_file, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filename,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isDownloading ? null : onDownload,
                  icon: isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Descargar'),
                ),
                OutlinedButton.icon(
                  onPressed: isDeactivating ? null : onDeactivate,
                  icon: isDeactivating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Quitar adjunto'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
