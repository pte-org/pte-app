class HostUser {
  HostUser({
    required this.publicId,
    required this.email,
    required this.fullName,
    required this.tenantId,
    required this.status,
    required List<String> roles,
  }) : roles = List.unmodifiable(roles);

  final String publicId;
  final String email;
  final String fullName;
  final String? tenantId;
  final String status;
  final List<String> roles;

  bool get isStudent => roles.contains('STUDENT');
  bool get isProctor => roles.contains('PROCTOR');
}
