import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/models/pending_attachment.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AttachmentsSection extends StatefulWidget {
  const AttachmentsSection({super.key});

  @override
  State<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends State<AttachmentsSection> {
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    if (!mounted) return;

    final inherited = UpsertCorrespondenceInherited.of(context);
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) continue;
      inherited.addPendingAttachment(
        PendingAttachment(
          filename: file.name,
          bytes: bytes,
          mimeType: file.extension,
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final inherited = UpsertCorrespondenceInherited.of(context);
    final attachments = inherited.pendingAttachments;

    return UpsertFormSection(
      title: 'Adjuntos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (attachments.isEmpty) ...[
            Text(
              'Los archivos se subirán al registrar la correspondencia.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Agregar archivos'),
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Agregar archivos'),
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(attachments.length, (index) {
              final attachment = attachments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(
                    attachment.filename,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${attachment.bytes.length} bytes'),
                  trailing: IconButton(
                    tooltip: 'Quitar',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      inherited.removePendingAttachmentAt(index);
                      setState(() {});
                    },
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
