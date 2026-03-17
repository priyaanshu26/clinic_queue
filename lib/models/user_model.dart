/// Model representing the logged-in user returned by POST /auth/login
class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // patient | doctor | receptionist | admin
  final int? clinicId;
  final String? clinicName;
  final String? clinicCode;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.clinicId,
    this.clinicName,
    this.clinicCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      clinicId: json['clinicId'] as int?,
      clinicName: json['clinicName'] as String?,
      clinicCode: json['clinicCode'] as String?,
    );
  }
}
