import 'package:equatable/equatable.dart';

class SentCount extends Equatable {
  const SentCount({required this.total});

  final int total;

  @override
  List<Object?> get props => [total];
}
