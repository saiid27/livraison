import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cashbox_transaction_model.dart';
import '../providers/admin_cashbox_provider.dart';

class AdminCashboxPage extends ConsumerStatefulWidget {
  const AdminCashboxPage({super.key});

  @override
  ConsumerState<AdminCashboxPage> createState() => _AdminCashboxPageState();
}

class _AdminCashboxPageState extends ConsumerState<AdminCashboxPage> {
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminCashboxProvider.notifier).loadCashbox(),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitExpense(bool isAr) async {
    final amount = _amountCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    if (amount.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            isAr
                ? 'اكتب مبلغ المصروف ووصفه'
                : 'Saisissez le montant et la description',
          ),
        ),
      );
      return;
    }

    final error = await ref
        .read(adminCashboxProvider.notifier)
        .createExpense(amount: amount, description: description);
    if (!mounted) return;
    if (error == null) {
      _amountCtrl.clear();
      _descriptionCtrl.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? AppColors.success : AppColors.error,
        content: Text(error ?? (isAr ? 'تم تسجيل المصروف' : 'Dépense ajoutée')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(adminCashboxProvider);
    final amountText = '${state.balance.toStringAsFixed(0)} MRU';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'الصندوق' : 'Caisse'),
        leading: IconButton(
          icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(adminCashboxProvider.notifier).loadCashbox(),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  TextFormField(
                    key: ValueKey(amountText),
                    readOnly: true,
                    initialValue: amountText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                    ),
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'المال المتوفر في الصندوق'
                          : 'Solde disponible',
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: isAr ? 'الدخل' : 'Revenus',
                          value: state.totalRecharges,
                          color: AppColors.primary,
                          icon: Icons.add_card_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryTile(
                          label: isAr ? 'المصروف' : 'Dépenses',
                          value: state.totalExpenses,
                          color: AppColors.error,
                          icon: Icons.remove_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ExpenseForm(
                    amountCtrl: _amountCtrl,
                    descriptionCtrl: _descriptionCtrl,
                    isAr: isAr,
                    isSubmitting: state.isSubmitting,
                    onSubmit: () => _submitExpense(isAr),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    isAr ? 'سجل المعاملات' : 'Historique',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (state.transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          isAr ? 'لا توجد معاملات' : 'Aucune transaction',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final transaction in state.transactions)
                      _TransactionTile(transaction: transaction, isAr: isAr),
                ],
              ),
            ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(0)} MRU',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ExpenseForm extends StatelessWidget {
  const _ExpenseForm({
    required this.amountCtrl,
    required this.descriptionCtrl,
    required this.isAr,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController amountCtrl;
  final TextEditingController descriptionCtrl;
  final bool isAr;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr ? 'تسجيل مصروف' : 'Ajouter une dépense',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isAr ? 'المبلغ المصروف' : 'Montant dépensé',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: isAr ? 'وصف المصروف' : 'Description',
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.remove_circle_outline),
            label: Text(isAr ? 'حفظ المصروف' : 'Enregistrer'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.isAr});

  final CashboxTransactionModel transaction;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? AppColors.error : AppColors.success;
    final date = DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt);
    final title = isExpense
        ? (isAr ? 'مصروف' : 'Dépense')
        : (isAr ? 'شحن' : 'Recharge');
    final subtitle = isExpense
        ? (transaction.description ?? '—')
        : [
            if (transaction.captainName != null) transaction.captainName!,
            if (transaction.orderId != null) '#${transaction.orderId}',
            if (transaction.description != null) transaction.description!,
          ].join(' - ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            isExpense ? Icons.remove : Icons.add_card_outlined,
            color: color,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('$subtitle\n$date'),
        isThreeLine: true,
        trailing: Text(
          '${isExpense ? '-' : '+'}${transaction.amount.toStringAsFixed(0)} MRU',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
