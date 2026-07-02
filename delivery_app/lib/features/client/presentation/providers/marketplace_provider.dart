import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../merchant/data/models/merchant_order_model.dart';
import '../../../merchant/data/models/merchant_product_model.dart';

class MarketplaceState {
  const MarketplaceState({
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

  MarketplaceState copyWith({
    List<MerchantProductModel>? products,
    List<MerchantOrderModel>? orders,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return MarketplaceState(
      products: products ?? this.products,
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  MarketplaceNotifier() : super(const MarketplaceState());

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get('/client/products');
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

  Future<String?> buyProduct(String productId, int quantity) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await ApiClient.instance.post(
        '/client/product-orders',
        data: {'product_id': productId, 'quantity': quantity},
      );
      await loadProducts();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return error.response?.data['message'] ?? 'Erreur';
    }
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, MarketplaceState>(
      (ref) => MarketplaceNotifier(),
    );
