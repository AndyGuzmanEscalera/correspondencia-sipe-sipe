import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/cubit/correspondence_attachments_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/widgets/correspondence_attachments_list.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CorrespondenceAttachmentsPage extends StatelessWidget {
  const CorrespondenceAttachmentsPage({
    required this.correspondenceId,
    super.key,
  });

  final String correspondenceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CorrespondenceAttachmentsCubit>(
        param1: correspondenceId,
      ),
      child: const CorrespondenceAttachmentsView(),
    );
  }
}

class CorrespondenceAttachmentsView extends StatelessWidget {
  const CorrespondenceAttachmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CorrespondenceAttachmentsCubit>();

    return MultiBlocListener(
      listeners: [
        ListenerPro<CorrespondenceAttachmentsCubit,
                CorrespondenceAttachmentsState>()
            .listen(showLoading: false),
      ],
      child: FullWidgetGeneric(
        onInit: cubit.init,
        child: const CorrespondenceAttachmentsBody(),
      ),
    );
  }
}

class CorrespondenceAttachmentsBody extends StatelessWidget {
  const CorrespondenceAttachmentsBody({super.key});

  Future<void> _pickAndUpload(BuildContext context) async {
    final cubit = context.read<CorrespondenceAttachmentsCubit>();
    if (cubit.state.uploading) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final uploads = <AttachmentUploadInput>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) {
        continue;
      }
      uploads.add(
        AttachmentUploadInput(
          filename: file.name,
          bytes: bytes,
          mimeType: file.extension,
        ),
      );
    }

    if (uploads.isEmpty) {
      return;
    }

    await cubit.uploadMultiple(uploads);
  }

  Widget _buildAddButton(
    BuildContext context,
    CorrespondenceAttachmentsState state, {
    bool expanded = false,
  }) {
    final button = OutlinedButton.icon(
      onPressed: state.uploading ? null : () => _pickAndUpload(context),
      icon: state.uploading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.upload_file_outlined),
      label: Text(state.uploading ? 'Subiendo...' : 'Agregar archivos'),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CorrespondenceAttachmentsCubit,
        CorrespondenceAttachmentsState>(
      builder: (context, state) {
        if (state.isRefreshing && state.attachments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final hasAttachments = state.attachments.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasAttachments)
              Align(
                alignment: Alignment.centerRight,
                child: _buildAddButton(context, state),
              )
            else
              Column(
                children: [
                  Text(
                    'No hay adjuntos registrados.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _buildAddButton(context, state, expanded: true),
                ],
              ),
            if (hasAttachments) ...[
              const SizedBox(height: 12),
              CorrespondenceAttachmentsList(
                attachments: state.attachments,
                downloadingAttachmentId: state.downloadingAttachmentId,
                deactivatingAttachmentId: state.deactivatingAttachmentId,
              ),
            ],
          ],
        );
      },
    );
  }
}
