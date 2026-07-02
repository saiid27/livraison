import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/merchant_order_model.dart';
import '../../data/models/merchant_product_model.dart';

class MerchantState {
  const MerchantState({
    this.products = const [],
    this.orders = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<MerchantProductModel> products;
  final List<MerchantOrderModel> orders;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  MerchantState copyWith({
    List<MerchantProductModel>? products,
    List<MerchantOrderModel>? orders,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return MerchantState(
      products: products ?? this.products,
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class MerchantNotifier extends StateNotifier<MerchantState> {
  MerchantNotifier() : super(const MerchantState());

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get('/merchant/products');
      final products = (response.data['products'] as List)
          .map((item) => MerchantProductModel.fromJson(item))
          .toList();
      state = state.copyWith(products: products, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.response?.data['message'] ?? 'Erreur',
      );
    }
  }

  Future<String?> saveProduct({
    String? id,
    required String name,
    required String price,
    required String quantity,
    String? imagePath,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final data = FormData.fromMap({
        'name': name,
        'price': price,
        'quantity': quantity,
        if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
      });
      if (id == null) {
        await ApiClient.instance.post('/merchant/products', data: data);
      } else {
        await ApiClient.instance.put('/merchant/products/$id', data: data);
      }
      await loadProducts();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return error.response?.data['message'] ?? 'Erreur';
    }
  }

  Future<void> loadOrders({bool salesOnly = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        salesOnly ? '/merchant/sales' : '/merchant/orders',
      );
      final orders = (response.data['orders'] as List)
          .map((item) => MerchantOrderModel.fromJson(item))
          .toList();
      state = state.copyWith(orders: orders, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.response?.data['message'] ?? 'Erreur',
      );
    }
  }

  Future<String?> updateOrderStatus(String orderId, String status) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await ApiClient.instance.put(
        '/merchant/orders/$orderId/status',
        data: {'status': status},
      );
      await loadOrders();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return error.response?.data['message'] ?? 'Erreur';
    }
  }

  Future<String?> updateProfile({
    required String contactPhone,
    required String paymentPhone,
    String? avatarPath,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final data = FormData.fromMap({
        'merchant_contact_phone': contactPhone,
        'merchant_payment_phone': paymentPhone,
        if (avatarPath != null)
          'profile_image': await MultipartFile.fromFile(avatarPath),
      });
      await ApiClient.instance.put('/merchant/profile', data: data);
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return error.response?.data['message'] ?? 'Erreur';
    }
  }
}

final merchantProvider = StateNotifierProvider<MerchantNotifier, MerchantState>(
  (ref) => MerchantNotifier(),
);
