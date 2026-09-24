import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/models/pending_attachment.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Adjuntos',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Agregar archivos'),
            ),
          ],
        ),
        if (attachments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Los archivos se subirán al registrar la correspondencia.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          )
        else
          ...List.generate(attachments.length, (index) {
            final attachment = attachments[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(attachment.filename),
              subtitle: Text('${attachment.bytes.length} bytes'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  inherited.removePendingAttachmentAt(index);
                  setState(() {});
                },
              ),
            );
          }),
      ],
    );
  }
}
