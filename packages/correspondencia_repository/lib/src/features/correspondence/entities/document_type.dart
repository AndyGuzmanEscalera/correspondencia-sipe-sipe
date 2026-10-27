import 'package:equatable/equatable.dart';

class DocumentType extends Equatable {
  const DocumentType({
    required this.id,
    required this.code,
    required this.name,
    this.profile = 'GENERIC',
    this.isOperational = false,
    this.creationPermission,
    this.minimumHierarchyId,
  });

  final String id;
  final String code;
  final String name;
  final String profile;
  final bool isOperational;
  final String? creationPermission;
  final String? minimumHierarchyId;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        profile,
        isOperational,
        creationPermission,
        minimumHierarchyId
      ];
}
