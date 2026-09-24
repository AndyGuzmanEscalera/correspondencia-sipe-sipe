part of 'correspondence_document_actions_cubit.dart';

class CorrespondenceDocumentActionsState extends Equatable
    implements StatusState {
  const CorrespondenceDocumentActionsState({
    this.openingChainingPdf = false,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final bool openingChainingPdf;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  CorrespondenceDocumentActionsState copyWith({
    bool? openingChainingPdf,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return CorrespondenceDocumentActionsState(
      openingChainingPdf: openingChainingPdf ?? this.openingChainingPdf,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        openingChainingPdf,
        dialogMessage,
        generalStatus,
      ];
}
