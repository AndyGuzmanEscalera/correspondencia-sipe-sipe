import 'package:equatable/equatable.dart';

class PositionAdmin extends Equatable {
  const PositionAdmin({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.description,
  });

  final String id;
  final String? code;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props =>
      [id, code, name, description, isActive, createdAt, updatedAt];
}

class PositionInput extends Equatable {
  const PositionInput({
    required this.code,
    required this.name,
    this.description,
  });

  final String code;
  final String name;
  final String? description;

  @override
  List<Object?> get props => [code, name, description];
}
