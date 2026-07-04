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
    super.merchantContactPhone,
    super.merchantPaymentPhone,
    super.isDeveloper,
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
      merchantContactPhone: json['merchant_contact_phone'],
      merchantPaymentPhone: json['merchant_payment_phone'],
      isDeveloper: json['is_developer'] == true,
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
    'merchant_contact_phone': merchantContactPhone,
    'merchant_payment_phone': merchantPaymentPhone,
    'is_developer': isDeveloper,
  };
}
