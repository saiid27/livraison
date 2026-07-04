import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../merchant/data/models/merchant_order_model.dart';
import '../../../merchant/data/models/merchant_payment_method_model.dart';
import '../../../merchant/data/models/merchant_product_model.dart';

class MarketplaceMerchantModel {
  const MarketplaceMerchantModel({
    required this.id,
    required this.name,
    required this.productCount,
    this.avatar,
    this.contactPhone,
    this.paymentPhone,
    this.paymentMethods = const [],
  });

  final String id;
  final String name;
  final String? avatar;
  final String? contactPhone;
  final String? paymentPhone;
  final List<MerchantPaymentMethodModel> paymentMethods;
  final int productCount;

  String? get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    if (avatar!.startsWith('http')) return avatar;
    return '${AppConstants.baseUrl.replaceAll('/api', '')}$avatar';
  }

  factory MarketplaceMerchantModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceMerchantModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      avatar: json['avatar'],
      contactPhone: json['merchant_contact_phone'],
      paymentPhone: json['merchant_payment_phone'],
      paymentMethods: (json['merchant_payment_methods'] as List? ?? [])
          .map((item) => MerchantPaymentMethodModel.fromJson(item))
          .toList(),
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MarketplaceState {
  const MarketplaceState({
    this.merchants = const [],
    this.products = const [],
    this.orders = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<MarketplaceMerchantModel> merchants;
  final List<MerchantProductModel> products;
  final List<MerchantOrderModel> orders;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  MarketplaceState copyWith({
    List<MarketplaceMerchantModel>? merchants,
    List<MerchantProductModel>? products,
    List<MerchantOrderModel>? orders,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return MarketplaceState(
      merchants: merchants ?? this.merchants,
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

  Future<void> loadMerchants() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get('/client/merchants');
      final merchants = (response.data['merchants'] as List)
          .map((item) => MarketplaceMerchantModel.fromJson(item))
          .toList();
      state = state.copyWith(merchants: merchants, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(isLoading: false, error: _errorMessage(error));
    }
  }

  Future<void> loadProducts({String? merchantId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '/client/products',
        queryParameters: {'merchant_id': ?merchantId},
      );
      final products = (response.data['products'] as List)
          .map((item) => MerchantProductModel.fromJson(item))
          .toList();
      state = state.copyWith(products: products, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(isLoading: false, error: _errorMessage(error));
    }
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get('/client/product-orders');
      final orders = (response.data['orders'] as List)
          .map((item) => MerchantOrderModel.fromJson(item))
          .toList();
      state = state.copyWith(orders: orders, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(isLoading: false, error: _errorMessage(error));
    }
  }

  Future<MerchantOrderModel?> buyProduct({
    required String productId,
    required String merchantId,
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
      await loadProducts(merchantId: merchantId);
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
