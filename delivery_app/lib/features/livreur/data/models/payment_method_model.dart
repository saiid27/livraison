class PaymentMethodModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? logoUrl;
  final bool isActive;

  const PaymentMethodModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.logoUrl,
    this.isActive = true,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      logoUrl: json['logo'],
      isActive: json['is_active'] ?? true,
    );
  }
}
