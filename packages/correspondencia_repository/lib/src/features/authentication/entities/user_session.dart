import 'package:equatable/equatable.dart';

import 'institutional_context.dart';

/// Represents the authenticated user as the UI consumes it.
///
/// Intentionally does NOT carry the access token — that lives in
/// [AuthTokenStore] in the api package.
class UserSession extends Equatable {
  const UserSession({
    required this.id,
    required this.username,
    required this.isActive,
    this.email,
    this.employeeId,
    this.institutionalContext,
    this.roles = const [],
    this.permissions = const [],
  });

  final String id;
  final String username;
  final bool isActive;
  final String? email;
  final String? employeeId;
  final InstitutionalContext? institutionalContext;
  final List<String> roles;
  final List<String> permissions;

  UserSession copyWith({
    String? id,
    String? username,
    bool? isActive,
    String? email,
    String? employeeId,
    InstitutionalContext? institutionalContext,
    List<String>? roles,
    List<String>? permissions,
  }) {
    return UserSession(
      id: id ?? this.id,
      username: username ?? this.username,
      isActive: isActive ?? this.isActive,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      institutionalContext: institutionalContext ?? this.institutionalContext,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        isActive,
        email,
        employeeId,
        institutionalContext,
        roles,
        permissions,
      ];
}
