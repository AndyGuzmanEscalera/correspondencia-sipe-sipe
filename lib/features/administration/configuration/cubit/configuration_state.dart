part of 'configuration_cubit.dart';

class ConfigurationState extends Equatable implements StatusState {
  const ConfigurationState({
    this.mayorDisplayName = '',
    this.loaded = false,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final String mayorDisplayName;
  final bool loaded;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  ConfigurationState copyWith({
    String? mayorDisplayName,
    bool? loaded,
    DialogMessage? dialogMessage,
    bool clearDialogMessage = false,
    GeneralStatus? generalStatus,
  }) {
    return ConfigurationState(
      mayorDisplayName: mayorDisplayName ?? this.mayorDisplayName,
      loaded: loaded ?? this.loaded,
      dialogMessage: clearDialogMessage
          ? const DialogMessage.empty()
          : (dialogMessage ?? this.dialogMessage),
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        mayorDisplayName,
        loaded,
        dialogMessage,
        generalStatus,
      ];
}
