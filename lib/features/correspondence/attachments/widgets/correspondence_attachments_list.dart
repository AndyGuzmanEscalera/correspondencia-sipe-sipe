import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/cubit/correspondence_attachments_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CorrespondenceAttachmentsList extends StatelessWidget {
  const CorrespondenceAttachmentsList({
    required this.attachments,
    super.key,
  });

  final List<CorrespondenceAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No hay adjuntos registrados.'),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      children: attachments.map((attachment) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.attach_file),
          title: Text(attachment.originalFilename ?? 'Archivo'),
          subtitle: Text(
            [
              if (attachment.sizeBytes != null) '${attachment.sizeBytes} bytes',
              dateFormat.format(attachment.createdAt),
              if (attachment.createdByUsername != null)
                attachment.createdByUsername,
            ].whereType<String>().join(' · '),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Descargar',
                icon: const Icon(Icons.download_outlined),
                onPressed: () => _download(context, attachment),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => context
                    .read<CorrespondenceAttachmentsCubit>()
                    .deactivate(attachment.id),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _download(
    BuildContext context,
    CorrespondenceAttachment attachment,
  ) async {
    final bytes = await context
        .read<CorrespondenceAttachmentsCubit>()
        .download(attachment.id);
    if (bytes == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Descarga lista (${bytes.length} bytes): '
          '${attachment.originalFilename ?? attachment.id}',
        ),
      ),
    );
  }
}
