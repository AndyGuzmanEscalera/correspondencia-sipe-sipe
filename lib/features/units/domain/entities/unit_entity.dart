import 'package:equatable/equatable.dart';

class UnitEntity extends Equatable {
  const UnitEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final bool isActive;

  @override
  List<Object?> get props => [id, code, name, isActive];
}
