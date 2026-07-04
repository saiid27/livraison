class WalletTransactionModel {
  final String id;
  final String type;
  final double amount;
  final String status;
  final String? description;
  final String? paymentMethodName;
  final String? orderId;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.description,
    this.paymentMethodName,
    this.orderId,
    required this.createdAt,
  });

  bool get isDebit => type == 'commission';
  bool get isRefund => type == 'commission_refund';

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'].toString(),
      type: json['type']?.toString() ?? 'recharge',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'verifie',
      description: json['description']?.toString(),
      paymentMethodName: json['payment_method_name']?.toString(),
      orderId: json['order_id']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
