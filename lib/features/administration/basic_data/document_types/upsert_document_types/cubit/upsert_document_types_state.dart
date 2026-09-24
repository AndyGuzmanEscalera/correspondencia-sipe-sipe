part of 'upsert_document_types_cubit.dart';

class UpsertDocumentTypesState extends Equatable implements StatusState {
  const UpsertDocumentTypesState({
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  UpsertDocumentTypesState copyWith({
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return UpsertDocumentTypesState(
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [dialogMessage, generalStatus];
}
