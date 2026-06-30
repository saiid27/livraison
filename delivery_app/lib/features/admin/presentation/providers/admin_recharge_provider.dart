import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../livreur/data/models/payment_method_model.dart';
import '../../../livreur/data/models/recharge_request_model.dart';

class AdminRechargeState {
  final List<RechargeRequestModel> requests;
  final List<PaymentMethodModel> paymentMethods;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const AdminRechargeState({
    this.requests = const [],
    this.paymentMethods = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  AdminRechargeState copyWith({
    List<RechargeRequestModel>? requests,
    List<PaymentMethodModel>? paymentMethods,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return AdminRechargeState(
      requests: requests ?? this.requests,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class AdminRechargeNotifier extends StateNotifier<AdminRechargeState> {
  AdminRechargeNotifier() : super(const AdminRechargeState());

  // ── Recharge requests ─────────────────────────────────────────────────────

  Future<void> loadRequests({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = status != null ? {'status': status} : null;
      final response = await ApiClient.instance.get(
        '/admin/recharge-requests',
        queryParameters: params,
      );
      final requests = (response.data['requests'] as List)
          .map((r) => RechargeRequestModel.fromJson(r))
          .toList();
      state = state.copyWith(requests: requests, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Erreur de chargement',
      );
    }
  }

  Future<String?> approveRequest(String requestId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await ApiClient.instance.put('/admin/recharge-requests/$requestId/approve');
      await loadRequests();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isSubmitting: false);
      return e.response?.data['message'] ?? 'Erreur';
    }
  }

  Future<String?> rejectRequest(String requestId, String reason) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await ApiClient.instance.put(
        '/admin/recharge-requests/$requestId/reject',
        data: {'reason': reason},
      );
      await loadRequests();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isSubmitting: false);
      return e.response?.data['message'] ?? 'Erreur';
    }
  }

  // ── Payment methods ───────────────────────────────────────────────────────

  Future<void> loadPaymentMethods() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get('/admin/payment-methods');
      final methods = (response.data['payment_methods'] as List)
          .map((m) => PaymentMethodModel.fromJson(m))
          .toList();
      state = state.copyWith(paymentMethods: methods, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Erreur',
      );
    }
  }

  Future<String?> createPaymentMethod({
    required String name,
    required String phoneNumber,
    String? logoPath,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final formData = FormData.fromMap({
        'name': name,
        'phone_number': phoneNumber,
        if (logoPath != null) 'logo': await MultipartFile.fromFile(logoPath),
      });
      await ApiClient.instance.post(
        '/admin/payment-methods',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      await loadPaymentMethods();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isSubmitting: false);
      return e.response?.data['message'] ?? 'Erreur';
    }
  }

  Future<String?> updatePaymentMethod({
    required String methodId,
    required String name,
    required String phoneNumber,
    bool? isActive,
    String? logoPath,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final formData = FormData.fromMap({
        'name': name,
        'phone_number': phoneNumber,
        if (isActive != null) 'is_active': isActive.toString(),
        if (logoPath != null) 'logo': await MultipartFile.fromFile(logoPath),
      });
      await ApiClient.instance.put(
        '/admin/payment-methods/$methodId',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      await loadPaymentMethods();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isSubmitting: false);
      return e.response?.data['message'] ?? 'Erreur';
    }
  }

  Future<String?> deletePaymentMethod(String methodId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await ApiClient.instance.delete('/admin/payment-methods/$methodId');
      await loadPaymentMethods();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isSubmitting: false);
      return e.response?.data['message'] ?? 'Erreur';
    }
  }
}

final adminRechargeProvider =
    StateNotifierProvider<AdminRechargeNotifier, AdminRechargeState>(
  (ref) => AdminRechargeNotifier(),
);
