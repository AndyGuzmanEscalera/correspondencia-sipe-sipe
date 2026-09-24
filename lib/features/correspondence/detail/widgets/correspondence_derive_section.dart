import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/views/derive_correspondence_view.dart';
import 'package:flutter/material.dart';

/// Sección de derivación. Futuras acciones (PDF, adjuntos) pueden seguir
/// el mismo patrón de widget hermano en [CorrespondenceDetailBody].
class CorrespondenceDeriveSection extends StatelessWidget {
  const CorrespondenceDeriveSection({
    required this.correspondenceId,
    super.key,
  });

  final String correspondenceId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Derivar trámite',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: AppDecorations.surfaceCard(elevated: false),
            clipBehavior: Clip.antiAlias,
            child: DeriveCorrespondencePage(
              correspondenceId: correspondenceId,
            ),
          ),
        ),
      ],
    );
  }
}
