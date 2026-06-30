import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../client/data/models/order_model.dart';

class LivreurState {
  final List<OrderModel> availableOrders;
  final List<OrderModel> myOrders;
  final bool isOnline;
  final bool isLoading;
  final String? error;

  const LivreurState({
    this.availableOrders = const [],
    this.myOrders = const [],
    this.isOnline = false,
    this.isLoading = false,
    this.error,
  });

  LivreurState copyWith({List<OrderModel>? availableOrders, List<OrderModel>? myOrders, bool? isOnline, bool? isLoading, String? error}) {
    return LivreurState(
      availableOrders: availableOrders ?? this.availableOrders,
      myOrders: myOrders ?? this.myOrders,
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LivreurNotifier extends StateNotifier<LivreurState> {
  LivreurNotifier() : super(const LivreurState());

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/livreur/available-orders'),
        ApiClient.instance.get('/livreur/my-orders'),
      ]);
      final available = (results[0].data['orders'] as List).map((o) => OrderModel.fromJson(o)).toList();
      final mine = (results[1].data['orders'] as List).map((o) => OrderModel.fromJson(o)).toList();
      state = state.copyWith(availableOrders: available, myOrders: mine, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data['message'] ?? 'Erreur');
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    try {
      await ApiClient.instance.post('/livreur/orders/$orderId/accept');
      await loadData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus(String orderId, String status) async {
    try {
      await ApiClient.instance.put('/livreur/orders/$orderId/status', data: {'status': status});
      await loadData();
      return true;
    } catch (_) {
      return false;
    }
  }

  void toggleOnline() => state = state.copyWith(isOnline: !state.isOnline);
}

final livreurProvider = StateNotifierProvider<LivreurNotifier, LivreurState>(
  (ref) => LivreurNotifier(),
);
