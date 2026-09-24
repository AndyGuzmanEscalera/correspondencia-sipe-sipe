part of 'correspondence_attachments_cubit.dart';

class CorrespondenceAttachmentsState extends Equatable implements StatusState {
  const CorrespondenceAttachmentsState({
    this.attachments = const [],
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final List<repo.CorrespondenceAttachment> attachments;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  CorrespondenceAttachmentsState copyWith({
    List<repo.CorrespondenceAttachment>? attachments,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return CorrespondenceAttachmentsState(
      attachments: attachments ?? this.attachments,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [attachments, dialogMessage, generalStatus];
}
