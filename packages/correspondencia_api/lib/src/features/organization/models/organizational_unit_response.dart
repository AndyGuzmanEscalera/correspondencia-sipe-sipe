class OrganizationalUnitResponse {
  const OrganizationalUnitResponse({
    required this.id,
    required this.code,
    required this.name,
  });

  factory OrganizationalUnitResponse.fromJson(Map<String, dynamic> json) {
    return OrganizationalUnitResponse(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String,
    );
  }

  final String id;
  final String code;
  final String name;
}
