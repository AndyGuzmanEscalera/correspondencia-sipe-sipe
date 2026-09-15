part of 'public_consult_cubit.dart';

class PublicConsultState extends Equatable implements StatusState {
  const PublicConsultState({
    required this.year,
    this.generalStatus = GeneralStatus.initial,
    this.dialogMessage = const DialogMessage.empty(),
    this.result,
  });

  final int year;

  @override
  final GeneralStatus generalStatus;

  @override
  final DialogMessage dialogMessage;

  final CorrespondenceEntity? result;

  PublicConsultState copyWith({
    int? year,
    GeneralStatus? generalStatus,
    DialogMessage? dialogMessage,
    CorrespondenceEntity? result,
  }) {
    return PublicConsultState(
      year: year ?? this.year,
      generalStatus: generalStatus ?? this.generalStatus,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      result: result,
    );
  }

  @override
  List<Object?> get props => [year, generalStatus, dialogMessage, result];
}
