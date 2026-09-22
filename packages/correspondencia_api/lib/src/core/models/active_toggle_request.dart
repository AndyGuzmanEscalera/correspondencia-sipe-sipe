class ActiveToggleRequest {
  const ActiveToggleRequest({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => {'is_active': isActive};
}
