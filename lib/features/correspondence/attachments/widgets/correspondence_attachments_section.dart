import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/views/correspondence_attachments_page.dart';
import 'package:flutter/material.dart';

class CorrespondenceAttachmentsSection extends StatelessWidget {
  const CorrespondenceAttachmentsSection({
    required this.correspondenceId,
    this.canManage = false,
    super.key,
  });

  final String correspondenceId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adjuntos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: AppDecorations.surfaceCard(elevated: false),
          padding: const EdgeInsets.all(16),
          child: CorrespondenceAttachmentsPage(
            correspondenceId: correspondenceId,
            canManage: canManage,
          ),
        ),
      ],
    );
  }
}
