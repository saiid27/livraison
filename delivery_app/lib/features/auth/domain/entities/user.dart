class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatar;
  final String approvalStatus;
  final String? idCardImage;
  final String? vehicleImage;
  final String? vehicleRegistrationImage;
  final String? permitImage;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    this.approvalStatus = 'approved',
    this.idCardImage,
    this.vehicleImage,
    this.vehicleRegistrationImage,
    this.permitImage,
  });
}
