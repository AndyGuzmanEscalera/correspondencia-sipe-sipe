class DocumentTypeResponse {
  const DocumentTypeResponse({
    required this.id,
    required this.code,
    required this.name,
  });

  factory DocumentTypeResponse.fromJson(Map<String, dynamic> json) {
    return DocumentTypeResponse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String code;
  final String name;
}
