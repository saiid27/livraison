import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/order_model.dart';
import '../../../../core/network/api_client.dart';

class OrderState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? error;

  const OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? error,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  OrderNotifier() : super(const OrderState());

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get('/client/orders');
      final orders = (response.data['orders'] as List)
          .map((o) => OrderModel.fromJson(o))
          .toList();
      state = state.copyWith(orders: orders, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Erreur de chargement',
      );
    }
  }

  Future<bool> createOrder({
    required String description,
    required String pickupAddress,
    required String deliveryAddress,
    required String serviceType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.post(
        '/client/orders',
        data: {
          'description': description,
          'pickup_address': pickupAddress,
          'delivery_address': deliveryAddress,
          'service_type': serviceType,
        },
      );
      final newOrder = OrderModel.fromJson(response.data['order']);
      state = state.copyWith(
        orders: [newOrder, ...state.orders],
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Erreur de création',
      );
      return false;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await ApiClient.instance.put('/client/orders/$orderId/cancel');
      final updated = state.orders.map((o) {
        if (o.id == orderId) {
          return OrderModel(
            id: o.id,
            clientId: o.clientId,
            description: o.description,
            pickupAddress: o.pickupAddress,
            deliveryAddress: o.deliveryAddress,
            serviceType: o.serviceType,
            price: o.price,
            status: 'annule',
            createdAt: o.createdAt,
          );
        }
        return o;
      }).toList();
      state = state.copyWith(orders: updated);
    } catch (_) {}
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>(
  (ref) => OrderNotifier(),
);
