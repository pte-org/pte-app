import '../../domain/host_user.dart';

class HostUserModel {
  const HostUserModel({
    required this.publicId,
    required this.email,
    required this.fullName,
    required this.tenantId,
    required this.status,
    required this.roles,
  });

  factory HostUserModel.fromJson(Map<String, dynamic> json) => HostUserModel(
    publicId: json['publicId'] as String,
    email: json['email'] as String,
    fullName: json['fullName'] as String,
    tenantId: json['tenantId'] as String?,
    status: json['status'] as String,
    roles: (json['roles'] as List<dynamic>).cast<String>(),
  );

  final String publicId;
  final String email;
  final String fullName;
  final String? tenantId;
  final String status;
  final List<String> roles;

  HostUser toEntity() => HostUser(
    publicId: publicId,
    email: email,
    fullName: fullName,
    tenantId: tenantId,
    status: status,
    roles: roles,
  );
}
