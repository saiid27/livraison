class AccountDeletionRequestModel {
  const AccountDeletionRequestModel({
    required this.id,
    required this.userName,
    required this.phone,
    required this.role,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.processedAt,
  });

  final String id;
  final String userName;
  final String phone;
  final String role;
  final String reason;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? processedAt;

  factory AccountDeletionRequestModel.fromJson(Map<String, dynamic> json) {
    return AccountDeletionRequestModel(
      id: json['id'].toString(),
      userName: json['user_name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      processedAt: json['processed_at'] == null
          ? null
          : DateTime.tryParse(json['processed_at']),
    );
  }
}
