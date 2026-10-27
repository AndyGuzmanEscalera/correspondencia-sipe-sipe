import 'package:equatable/equatable.dart';

class PositionAdmin extends Equatable {
  const PositionAdmin({
    required this.id,
    this.hierarchyCode,
    this.hierarchyName,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.description,
    this.canViewUnitCorrespondence = false,
    this.hierarchyId,
  });

  final String id;
  final String? hierarchyCode;
  final String? hierarchyName;
  final String? code;
  final String name;
  final String? description;
  final bool canViewUnitCorrespondence;
  final String? hierarchyId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        description,
        canViewUnitCorrespondence,
        hierarchyId,
        hierarchyCode,
        hierarchyName,
        isActive,
        createdAt,
        updatedAt
      ];
}

class PositionInput extends Equatable {
  const PositionInput({
    required this.code,
    required this.name,
    this.description,
    this.canViewUnitCorrespondence = false,
    this.hierarchyId,
  });

  final String code;
  final String name;
  final String? description;
  final bool canViewUnitCorrespondence;
  final String? hierarchyId;

  @override
  List<Object?> get props =>
      [code, name, description, canViewUnitCorrespondence, hierarchyId];
}

class PositionHierarchy extends Equatable {
  const PositionHierarchy(
      {required this.id,
      required this.code,
      required this.name,
      required this.rank,
      this.isActive = true});
  final String id;
  final String code;
  final String name;
  final int rank;
  final bool isActive;
  @override
  List<Object?> get props => [id, code, name, rank, isActive];
}
