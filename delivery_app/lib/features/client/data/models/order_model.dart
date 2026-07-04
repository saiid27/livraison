class OrderModel {
  final String id;
  final String clientId;
  final String? livreurId;
  final String description;
  final String pickupAddress;
  final String deliveryAddress;
  final String serviceType;
  final double? price;
  final String status;
  final String? livreurName;
  final String? livreurPhone;
  final String? clientName;
  final String? clientPhone;
  final String? cancellationReason;
  final DateTime? pickedUpAt;
  final DateTime? commissionChargedAt;
  final double? commissionAmount;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.clientId,
    this.livreurId,
    required this.description,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.serviceType = 'delivery',
    this.price,
    required this.status,
    this.livreurName,
    this.livreurPhone,
    this.clientName,
    this.clientPhone,
    this.cancellationReason,
    this.pickedUpAt,
    this.commissionChargedAt,
    this.commissionAmount,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'].toString(),
      clientId: json['client_id'].toString(),
      livreurId: json['livreur_id']?.toString(),
      description: json['description'] ?? '',
      pickupAddress: json['pickup_address'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      serviceType: json['service_type'] ?? 'delivery',
      price: (json['price'] as num?)?.toDouble(),
      status: json['status'] ?? 'en_attente',
      livreurName: json['livreur_name'],
      livreurPhone: json['livreur_phone'],
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      cancellationReason: json['cancellation_reason'],
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.tryParse(json['picked_up_at'].toString())
          : null,
      commissionChargedAt: json['commission_charged_at'] != null
          ? DateTime.tryParse(json['commission_charged_at'].toString())
          : null,
      commissionAmount: (json['commission_amount'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
