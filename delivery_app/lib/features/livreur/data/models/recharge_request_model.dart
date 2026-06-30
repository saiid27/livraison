class RechargeRequestModel {
  final String id;
  final String captainId;
  final String? captainName;
  final String paymentMethodId;
  final String? paymentMethodName;
  final double amount;
  final String phoneFrom;
  final String? screenshotUrl;
  final String status; // en_attente | verifie | refuse
  final String? rejectionReason;
  final DateTime createdAt;

  const RechargeRequestModel({
    required this.id,
    required this.captainId,
    this.captainName,
    required this.paymentMethodId,
    this.paymentMethodName,
    required this.amount,
    required this.phoneFrom,
    this.screenshotUrl,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  factory RechargeRequestModel.fromJson(Map<String, dynamic> json) {
    return RechargeRequestModel(
      id: json['id'].toString(),
      captainId: json['captain_id'].toString(),
      captainName: json['captain_name'],
      paymentMethodId: json['payment_method_id'].toString(),
      paymentMethodName: json['payment_method_name'],
      amount: (json['amount'] as num).toDouble(),
      phoneFrom: json['phone_from'] ?? '',
      screenshotUrl: json['screenshot'],
      status: json['status'] ?? 'en_attente',
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
