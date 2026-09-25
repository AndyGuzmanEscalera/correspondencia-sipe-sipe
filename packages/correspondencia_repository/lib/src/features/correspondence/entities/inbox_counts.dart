import 'package:equatable/equatable.dart';

class InboxCounts extends Equatable {
  const InboxCounts({
    required this.mine,
    required this.unit,
  });

  final int mine;
  final int unit;

  @override
  List<Object?> get props => [mine, unit];
}
