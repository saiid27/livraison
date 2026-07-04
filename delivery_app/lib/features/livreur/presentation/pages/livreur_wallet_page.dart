import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../providers/livreur_provider.dart';
import '../providers/wallet_provider.dart';
import '../../data/models/wallet_transaction_model.dart';

class LivreurWalletPage extends ConsumerStatefulWidget {
  final String baseRoute;

  const LivreurWalletPage({super.key, this.baseRoute = '/livreur'});

  @override
  ConsumerState<LivreurWalletPage> createState() => _LivreurWalletPageState();
}

class _LivreurWalletPageState extends ConsumerState<LivreurWalletPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(livreurProvider.notifier).loadWallet();
      ref.read(walletProvider.notifier).loadAll();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(livreurProvider.notifier).loadWallet(),
      ref.read(walletProvider.notifier).loadAll(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final livreurState = ref.watch(livreurProvider);
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'المحفظة' : 'Portefeuille'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(widget.baseRoute),
        ),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Balance card ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'رصيدي' : 'Mon solde',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${livreurState.balance.toStringAsFixed(2)} ${isAr ? 'أوقية' : 'MRU'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr ? 'عمولة المنصة: 9%' : 'Commission plateforme : 9%',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Recharge button ────────────────────────────────────
              ElevatedButton.icon(
                onPressed: () => context.go('${widget.baseRoute}/recharge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_card_rounded),
                label: Text(
                  isAr ? 'شحن الرصيد' : 'Recharger le solde',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Wallet history ─────────────────────────────────────
              Text(
                isAr ? 'سجل المحفظة' : 'Historique du portefeuille',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (walletState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (walletState.transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isAr
                              ? 'لا توجد عمليات في المحفظة بعد'
                              : 'Aucune opération pour le moment',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...walletState.transactions.map(
                  (transaction) => _WalletTransactionCard(
                    transaction: transaction,
                    isAr: isAr,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── History card ──────────────────────────────────────────────────────────────

class _WalletTransactionCard extends StatelessWidget {
  final WalletTransactionModel transaction;
  final bool isAr;

  const _WalletTransactionCard({required this.transaction, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');
    final (label, color, icon) = _statusInfo(transaction);
    final sign = transaction.isDebit ? '-' : '+';
    final title = transaction.type == 'commission'
        ? (isAr ? 'عمولة الطلب' : 'Commission commande')
        : transaction.type == 'commission_refund'
        ? (isAr ? 'إرجاع عمولة' : 'Remboursement commission')
        : (isAr ? 'شحن رصيد' : 'Recharge');
    final subtitle = transaction.type == 'recharge'
        ? (transaction.paymentMethodName ?? '')
        : [
            title,
            if (transaction.orderId != null) '#${transaction.orderId}',
          ].join(' ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sign ${transaction.amount.toStringAsFixed(0)} ${isAr ? 'أوقية' : 'MRU'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: transaction.isDebit
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (transaction.status == 'refuse' &&
                      transaction.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${isAr ? 'السبب: ' : 'Motif : '}${transaction.description}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Date + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(transaction.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  timeFmt.format(transaction.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, IconData) _statusInfo(WalletTransactionModel transaction) {
    if (transaction.type == 'commission') {
      return (
        isAr ? 'تم الخصم' : 'Débité',
        AppColors.error,
        Icons.remove_circle_outline,
      );
    }
    if (transaction.type == 'commission_refund') {
      return (
        isAr ? 'تم الإرجاع' : 'Remboursé',
        AppColors.success,
        Icons.undo_outlined,
      );
    }
    return switch (transaction.status) {
      'verifie' => (
        isAr ? 'تم التحقق' : 'Vérifié',
        AppColors.success,
        Icons.check_circle_outline_rounded,
      ),
      'refuse' => (
        isAr ? 'مرفوض' : 'Refusé',
        AppColors.error,
        Icons.cancel_outlined,
      ),
      _ => (
        isAr ? 'في الانتظار' : 'En attente',
        AppColors.warning,
        Icons.hourglass_empty_rounded,
      ),
    };
  }
}
