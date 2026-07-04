import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../client/data/models/order_model.dart';

class LivreurState {
  final List<OrderModel> availableOrders;
  final List<OrderModel> myOrders;
  final bool isOnline;
  final bool isLoading;
  final double balance;
  final String? error;

  const LivreurState({
    this.availableOrders = const [],
    this.myOrders = const [],
    this.isOnline = false,
    this.isLoading = false,
    this.balance = 0.0,
    this.error,
  });

  LivreurState copyWith({
    List<OrderModel>? availableOrders,
    List<OrderModel>? myOrders,
    bool? isOnline,
    bool? isLoading,
    double? balance,
    String? error,
  }) {
    return LivreurState(
      availableOrders: availableOrders ?? this.availableOrders,
      myOrders: myOrders ?? this.myOrders,
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      balance: balance ?? this.balance,
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
      final available = (results[0].data['orders'] as List)
          .map((o) => OrderModel.fromJson(o))
          .toList();
      final mine = (results[1].data['orders'] as List)
          .map((o) => OrderModel.fromJson(o))
          .toList();
      state = state.copyWith(
        availableOrders: available,
        myOrders: mine,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Erreur',
      );
    }
  }

  Future<void> loadWallet() async {
    try {
      final response = await ApiClient.instance.get('/livreur/wallet');
      final balance = (response.data['balance'] as num).toDouble();
      state = state.copyWith(balance: balance);
    } catch (_) {}
  }

  /// Returns null on success, or an error code string on failure.
  Future<String?> acceptOrder(String orderId) async {
    try {
      await ApiClient.instance.post('/livreur/orders/$orderId/accept');
      await loadData();
      await loadWallet();
      return null;
    } on DioException catch (e) {
      final code = e.response?.data['code'] as String?;
      return code ?? 'error';
    } catch (_) {
      return 'error';
    }
  }

  Future<String?> confirmPickup(String orderId) async {
    try {
      await ApiClient.instance.post('/livreur/orders/$orderId/pickup');
      await loadData();
      await loadWallet();
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['code'] != null) {
        return data['code'].toString();
      }
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'error';
    } catch (_) {
      return 'error';
    }
  }

  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      await ApiClient.instance.post(
        '/livreur/orders/$orderId/cancel',
        data: {'reason': reason},
      );
      await loadData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStatus(String orderId, String status) async {
    try {
      await ApiClient.instance.put(
        '/livreur/orders/$orderId/status',
        data: {'status': status},
      );
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
