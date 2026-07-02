import '../../../../core/constants/app_constants.dart';
import 'merchant_payment_method_model.dart';

class MerchantOrderModel {
  const MerchantOrderModel({
    required this.id,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.merchantName,
    this.merchantContactPhone,
    this.merchantPaymentPhone,
    this.merchantPaymentMethods = const [],
    this.clientName,
    this.clientPhone,
    this.productImage,
    this.paymentPhoneFrom,
    this.paymentScreenshot,
    this.buyerName,
    this.notes,
  });

  final String id;
  final String? merchantName;
  final String? merchantContactPhone;
  final String? merchantPaymentPhone;
  final List<MerchantPaymentMethodModel> merchantPaymentMethods;
  final String? clientName;
  final String? clientPhone;
  final String productName;
  final String? productImage;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final String? paymentPhoneFrom;
  final String? paymentScreenshot;
  final String? buyerName;
  final String? notes;

  String? get imageUrl {
    if (productImage == null || productImage!.isEmpty) return null;
    if (productImage!.startsWith('http')) return productImage;
    return '${AppConstants.baseUrl.replaceAll('/api', '')}$productImage';
  }

  String? get screenshotUrl {
    if (paymentScreenshot == null || paymentScreenshot!.isEmpty) return null;
    if (paymentScreenshot!.startsWith('http')) return paymentScreenshot;
    return '${AppConstants.baseUrl.replaceAll('/api', '')}$paymentScreenshot';
  }

  factory MerchantOrderModel.fromJson(Map<String, dynamic> json) {
    return MerchantOrderModel(
      id: json['id'].toString(),
      merchantName: json['merchant_name'],
      merchantContactPhone: json['merchant_contact_phone'],
      merchantPaymentPhone: json['merchant_payment_phone'],
      merchantPaymentMethods: (json['merchant_payment_methods'] as List? ?? [])
          .map((item) => MerchantPaymentMethodModel.fromJson(item))
          .toList(),
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      paymentPhoneFrom: json['payment_phone_from'],
      paymentScreenshot: json['payment_screenshot'],
      buyerName: json['buyer_name'],
      notes: json['notes'],
    );
  }
}
