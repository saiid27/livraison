import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/payment_method_model.dart';
import '../../data/models/recharge_request_model.dart';

class WalletState {
  final List<RechargeRequestModel> requests;
  final List<PaymentMethodModel> paymentMethods;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const WalletState({
    this.requests = const [],
    this.paymentMethods = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  WalletState copyWith({
    List<RechargeRequestModel>? requests,
    List<PaymentMethodModel>? paymentMethods,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return WalletState(
      requests: requests ?? this.requests,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/livreur/recharge-requests'),
        ApiClient.instance.get('/livreur/payment-methods'),
      ]);
      final requests = (results[0].data['requests'] as List)
          .map((r) => RechargeRequestModel.fromJson(r))
          .toList();
      final methods = (results[1].data['payment_methods'] as List)
          .map((m) => PaymentMethodModel.fromJson(m))
          .toList();
      state = state.copyWith(
        requests: requests,
        paymentMethods: methods,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Erreur de chargement',
      );
    }
  }

  Future<void> loadPaymentMethods() async {
    try {
      final response = await ApiClient.instance.get('/livreur/payment-methods');
      final methods = (response.data['payment_methods'] as List)
          .map((m) => PaymentMethodModel.fromJson(m))
          .toList();
      state = state.copyWith(paymentMethods: methods);
    } catch (_) {}
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> submitRequest({
    required double amount,
    required String phoneFrom,
    required String paymentMethodId,
    String? screenshotPath,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final formData = FormData.fromMap({
        'amount': amount.toString(),
        'phone_from': phoneFrom,
        'payment_method_id': paymentMethodId,
        if (screenshotPath != null)
          'screenshot': await MultipartFile.fromFile(screenshotPath),
      });
      await ApiClient.instance.post(
        '/livreur/recharge-requests',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Erreur lors de la soumission';
      state = state.copyWith(isSubmitting: false, error: msg);
      return msg;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>(
  (ref) => WalletNotifier(),
);
