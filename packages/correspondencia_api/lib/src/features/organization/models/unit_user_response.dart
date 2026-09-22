class UnitUserResponse {
  const UnitUserResponse({
    required this.id,
    required this.username,
    required this.displayName,
  });

  factory UnitUserResponse.fromJson(Map<String, dynamic> json) {
    return UnitUserResponse(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
    );
  }

  final String id;
  final String username;
  final String displayName;
}
