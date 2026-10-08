import 'package:equatable/equatable.dart';

class InboxCounts extends Equatable {
  const InboxCounts({
    required this.mine,
    required this.unit,
    this.canViewUnitCorrespondence = false,
  });

  final int mine;
  final int unit;
  final bool canViewUnitCorrespondence;

  @override
  List<Object?> get props => [mine, unit, canViewUnitCorrespondence];
}
