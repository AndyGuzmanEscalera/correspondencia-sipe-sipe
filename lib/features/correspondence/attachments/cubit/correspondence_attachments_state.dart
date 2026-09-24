part of 'correspondence_attachments_cubit.dart';

class CorrespondenceAttachmentsState extends Equatable implements StatusState {
  const CorrespondenceAttachmentsState({
    this.attachments = const [],
    this.isRefreshing = false,
    this.uploading = false,
    this.downloadingAttachmentId,
    this.deactivatingAttachmentId,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final List<repo.CorrespondenceAttachment> attachments;
  final bool isRefreshing;
  final bool uploading;
  final String? downloadingAttachmentId;
  final String? deactivatingAttachmentId;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  CorrespondenceAttachmentsState copyWith({
    List<repo.CorrespondenceAttachment>? attachments,
    bool? isRefreshing,
    bool? uploading,
    String? downloadingAttachmentId,
    bool clearDownloadingAttachmentId = false,
    String? deactivatingAttachmentId,
    bool clearDeactivatingAttachmentId = false,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return CorrespondenceAttachmentsState(
      attachments: attachments ?? this.attachments,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      uploading: uploading ?? this.uploading,
      downloadingAttachmentId: clearDownloadingAttachmentId
          ? null
          : (downloadingAttachmentId ?? this.downloadingAttachmentId),
      deactivatingAttachmentId: clearDeactivatingAttachmentId
          ? null
          : (deactivatingAttachmentId ?? this.deactivatingAttachmentId),
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        attachments,
        isRefreshing,
        uploading,
        downloadingAttachmentId,
        deactivatingAttachmentId,
        dialogMessage,
        generalStatus,
      ];
}

class AttachmentUploadInput extends Equatable {
  const AttachmentUploadInput({
    required this.filename,
    required this.bytes,
    this.mimeType,
  });

  final String filename;
  final List<int> bytes;
  final String? mimeType;

  @override
  List<Object?> get props => [filename, bytes, mimeType];
}
