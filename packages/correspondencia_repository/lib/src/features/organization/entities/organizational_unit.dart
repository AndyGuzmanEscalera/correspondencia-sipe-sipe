import 'package:equatable/equatable.dart';

class OrganizationalUnit extends Equatable {
  const OrganizationalUnit({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;

  @override
  List<Object?> get props => [id, code, name];
}

class UnitUser extends Equatable {
  const UnitUser({
    required this.id,
    required this.username,
    required this.displayName,
  });

  final String id;
  final String username;
  final String displayName;

  @override
  List<Object?> get props => [id, username, displayName];
}
