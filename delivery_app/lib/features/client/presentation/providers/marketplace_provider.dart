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

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return 'Erreur';
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get('/client/products');
      final products = (response.data['products'] as List)
          .map((item) => MerchantProductModel.fromJson(item))
          .toList();
      state = state.copyWith(products: products, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(isLoading: false, error: _errorMessage(error));
    }
  }

  Future<MerchantOrderModel?> buyProduct({
    required String productId,
    required int quantity,
    required String buyerName,
    required String paymentPhoneFrom,
    required String screenshotPath,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final data = FormData.fromMap({
        'product_id': productId,
        'quantity': quantity,
        'buyer_name': buyerName,
        'payment_phone_from': paymentPhoneFrom,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'payment_screenshot': await MultipartFile.fromFile(screenshotPath),
      });
      final response = await ApiClient.instance.post(
        '/client/product-orders',
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      );
      final order = MerchantOrderModel.fromJson(response.data['order']);
      await loadProducts();
      state = state.copyWith(isSubmitting: false);
      return order;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false, error: _errorMessage(error));
      return null;
    }
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, MarketplaceState>(
      (ref) => MarketplaceNotifier(),
    );
