import 'package:equatable/equatable.dart';

class InstitutionalSettings extends Equatable {
  const InstitutionalSettings({this.mayorDisplayName});

  final String? mayorDisplayName;

  @override
  List<Object?> get props => [mayorDisplayName];
}
