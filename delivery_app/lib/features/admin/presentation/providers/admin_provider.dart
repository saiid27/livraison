import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../client/data/models/order_model.dart';
import '../../../auth/data/models/user_model.dart';

class AdminState {
  final List<OrderModel> orders;
  final List<UserModel> users;
  final Map<String, int> stats;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.orders = const [],
    this.users = const [],
    this.stats = const {},
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<OrderModel>? orders,
    List<UserModel>? users,
    Map<String, int>? stats,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      orders: orders ?? this.orders,
      users: users ?? this.users,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(const AdminState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiClient.instance.get('/admin/dashboard');
      final stats = Map<String, int>.from(response.data['stats'] ?? {});
      state = state.copyWith(stats: stats, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Erreur',
      );
    }
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiClient.instance.get('/admin/orders');
      final orders = (response.data['orders'] as List)
          .map((o) => OrderModel.fromJson(o))
          .toList();
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiClient.instance.get('/admin/users');
      final users = (response.data['users'] as List)
          .map((u) => UserModel.fromJson(u))
          .toList();
      state = state.copyWith(users: users, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadPendingCaptains() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get('/admin/captains/pending');
      final users = (response.data['users'] as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
      state = state.copyWith(users: users, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.response?.data['message'] ?? 'Erreur',
      );
    }
  }

  Future<void> updateCaptainApproval(String userId, String status) async {
    await ApiClient.instance.put(
      '/admin/captains/$userId/approval',
      data: {'status': status},
    );
    await loadPendingCaptains();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await ApiClient.instance.put(
        '/admin/orders/$orderId/status',
        data: {'status': status},
      );
      await loadOrders();
    } catch (_) {}
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>(
  (ref) => AdminNotifier(),
);
