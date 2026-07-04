import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/cashbox_transaction_model.dart';

class AdminCashboxState {
  const AdminCashboxState({
    this.balance = 0,
    this.totalRecharges = 0,
    this.totalExpenses = 0,
    this.transactions = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final double balance;
  final double totalRecharges;
  final double totalExpenses;
  final List<CashboxTransactionModel> transactions;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  AdminCashboxState copyWith({
    double? balance,
    double? totalRecharges,
    double? totalExpenses,
    List<CashboxTransactionModel>? transactions,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return AdminCashboxState(
      balance: balance ?? this.balance,
      totalRecharges: totalRecharges ?? this.totalRecharges,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class AdminCashboxNotifier extends StateNotifier<AdminCashboxState> {
  AdminCashboxNotifier() : super(const AdminCashboxState());

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Erreur';
  }

  Future<void> loadCashbox() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get('/admin/cashbox');
      final transactions = (response.data['transactions'] as List)
          .map((item) => CashboxTransactionModel.fromJson(item))
          .toList();
      state = state.copyWith(
        balance: (response.data['balance'] as num?)?.toDouble() ?? 0,
        totalRecharges:
            (response.data['total_recharges'] as num?)?.toDouble() ?? 0,
        totalExpenses:
            (response.data['total_expenses'] as num?)?.toDouble() ?? 0,
        transactions: transactions,
        isLoading: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  Future<String?> createExpense({
    required String amount,
    required String description,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await ApiClient.instance.post(
        '/admin/cashbox/expenses',
        data: {'amount': amount, 'description': description},
      );
      await loadCashbox();
      state = state.copyWith(isSubmitting: false);
      return null;
    } on DioException catch (error) {
      final message = _message(error);
      state = state.copyWith(isSubmitting: false, error: message);
      return message;
    }
  }
}

final adminCashboxProvider =
    StateNotifierProvider<AdminCashboxNotifier, AdminCashboxState>(
      (ref) => AdminCashboxNotifier(),
    );
