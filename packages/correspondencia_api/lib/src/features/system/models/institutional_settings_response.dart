class InstitutionalSettingsResponse {
  const InstitutionalSettingsResponse({this.mayorDisplayName});

  final String? mayorDisplayName;

  factory InstitutionalSettingsResponse.fromJson(Map<String, dynamic> json) {
    return InstitutionalSettingsResponse(
      mayorDisplayName: json['mayor_display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (mayorDisplayName != null) 'mayor_display_name': mayorDisplayName,
      };
}
