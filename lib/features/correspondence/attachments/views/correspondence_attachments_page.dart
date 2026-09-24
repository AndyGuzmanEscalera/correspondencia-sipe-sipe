import 'package:correspondencia_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/listener/listener_generic.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
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
            CorrespondenceAttachmentsState>().listen(),
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
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    await context.read<CorrespondenceAttachmentsCubit>().upload(
          filename: file.name,
          bytes: bytes,
          mimeType: file.extension,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CorrespondenceAttachmentsCubit,
        CorrespondenceAttachmentsState>(
      builder: (context, state) {
        final isLoading = state.generalStatus == GeneralStatus.loading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isLoading ? null : () => _pickAndUpload(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Subir adjunto'),
              ),
            ),
            if (state.generalStatus == GeneralStatus.loading &&
                state.attachments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              CorrespondenceAttachmentsList(attachments: state.attachments),
          ],
        );
      },
    );
  }
}
