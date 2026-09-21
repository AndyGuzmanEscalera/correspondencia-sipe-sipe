import 'package:equatable/equatable.dart';

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
  });

  final String id;
  final String username;
  final bool isActive;
  final String? email;
  final String? employeeId;

  UserSession copyWith({
    String? id,
    String? username,
    bool? isActive,
    String? email,
    String? employeeId,
  }) {
    return UserSession(
      id: id ?? this.id,
      username: username ?? this.username,
      isActive: isActive ?? this.isActive,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  @override
  List<Object?> get props => [id, username, isActive, email, employeeId];
}
