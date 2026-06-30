import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.avatar,
    super.approvalStatus,
    super.idCardImage,
    super.vehicleImage,
    super.vehicleRegistrationImage,
    super.permitImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'client',
      avatar: json['avatar'],
      approvalStatus: json['approval_status'] ?? 'approved',
      idCardImage: json['id_card_image'],
      vehicleImage: json['vehicle_image'],
      vehicleRegistrationImage: json['vehicle_registration_image'],
      permitImage: json['permit_image'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'avatar': avatar,
    'approval_status': approvalStatus,
    'id_card_image': idCardImage,
    'vehicle_image': vehicleImage,
    'vehicle_registration_image': vehicleRegistrationImage,
    'permit_image': permitImage,
  };
}
