import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/account_deletion_request_model.dart';

class AdminAccountDeletionState {
  const AdminAccountDeletionState({
    this.requests = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<AccountDeletionRequestModel> requests;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  AdminAccountDeletionState copyWith({
    List<AccountDeletionRequestModel>? requests,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return AdminAccountDeletionState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class AdminAccountDeletionNotifier
    extends StateNotifier<AdminAccountDeletionState> {
  AdminAccountDeletionNotifier() : super(const AdminAccountDeletionState());

  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '/admin/account-deletion-requests',
      );
      final requests = (response.data['requests'] as List)
          .map((item) => AccountDeletionRequestModel.fromJson(item))
          .toList();
      state = state.copyWith(requests: requests, isLoading: false);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.response?.data['message'] ?? 'Erreur',
      );
    }
  }

  Future<String?> approve(String requestId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await ApiClient.instance.put(
        '/admin/account-deletion-requests/$requestId/approve',
      );
      await loadRequests();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return error.response?.data['message'] ?? 'Erreur';
    }
  }

  Future<String?> reject(String requestId, String reason) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await ApiClient.instance.put(
        '/admin/account-deletion-requests/$requestId/reject',
        data: {'reason': reason},
      );
      await loadRequests();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false);
      return error.response?.data['message'] ?? 'Erreur';
    }
  }
}

final adminAccountDeletionProvider =
    StateNotifierProvider<
      AdminAccountDeletionNotifier,
      AdminAccountDeletionState
    >((ref) => AdminAccountDeletionNotifier());
