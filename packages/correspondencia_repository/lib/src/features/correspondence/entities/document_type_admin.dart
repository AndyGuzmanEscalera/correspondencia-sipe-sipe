import 'package:equatable/equatable.dart';

class DocumentTypeAdmin extends Equatable {
  const DocumentTypeAdmin({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props =>
      [id, code, name, isActive, createdAt, updatedAt];
}

class DocumentTypeInput extends Equatable {
  const DocumentTypeInput({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  @override
  List<Object?> get props => [code, name];
}

class DocumentTypeUpdateInput extends Equatable {
  const DocumentTypeUpdateInput({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}
