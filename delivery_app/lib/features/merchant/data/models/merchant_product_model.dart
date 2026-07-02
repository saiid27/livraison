import '../../../../core/constants/app_constants.dart';
import 'merchant_payment_method_model.dart';

class MerchantProductModel {
  const MerchantProductModel({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.createdAt,
    this.merchantName,
    this.merchantContactPhone,
    this.merchantPaymentPhone,
    this.merchantPaymentMethods = const [],
    this.image,
  });

  final String id;
  final String merchantId;
  final String? merchantName;
  final String? merchantContactPhone;
  final String? merchantPaymentPhone;
  final List<MerchantPaymentMethodModel> merchantPaymentMethods;
  final String name;
  final double price;
  final int quantity;
  final String? image;
  final DateTime createdAt;

  String? get imageUrl {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http')) return image;
    return '${AppConstants.baseUrl.replaceAll('/api', '')}$image';
  }

  factory MerchantProductModel.fromJson(Map<String, dynamic> json) {
    return MerchantProductModel(
      id: json['id'].toString(),
      merchantId: json['merchant_id'].toString(),
      merchantName: json['merchant_name'],
      merchantContactPhone: json['merchant_contact_phone'],
      merchantPaymentPhone: json['merchant_payment_phone'],
      merchantPaymentMethods: (json['merchant_payment_methods'] as List? ?? [])
          .map((item) => MerchantPaymentMethodModel.fromJson(item))
          .toList(),
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      image: json['image'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
