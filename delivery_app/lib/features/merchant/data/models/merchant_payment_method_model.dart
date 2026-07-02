class MerchantPaymentMethodModel {
  const MerchantPaymentMethodModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  final String id;
  final String name;
  final String phoneNumber;

  factory MerchantPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return MerchantPaymentMethodModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
    );
  }
}
