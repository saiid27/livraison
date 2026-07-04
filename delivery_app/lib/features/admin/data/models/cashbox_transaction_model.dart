class CashboxTransactionModel {
  const CashboxTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.description,
    this.captainName,
    this.rechargeRequestId,
  });

  final String id;
  final String type;
  final double amount;
  final String? description;
  final String? captainName;
  final String? rechargeRequestId;
  final DateTime createdAt;

  factory CashboxTransactionModel.fromJson(Map<String, dynamic> json) {
    return CashboxTransactionModel(
      id: json['id'].toString(),
      type: json['type']?.toString() ?? 'expense',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString(),
      captainName: json['captain_name']?.toString(),
      rechargeRequestId: json['recharge_request_id']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
