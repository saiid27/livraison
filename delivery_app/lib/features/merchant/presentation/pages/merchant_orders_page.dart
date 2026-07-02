import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/merchant_order_model.dart';
import '../providers/merchant_provider.dart';
import '../widgets/merchant_widgets.dart';

class MerchantOrdersPage extends ConsumerStatefulWidget {
  const MerchantOrdersPage({
    super.key,
    this.salesOnly = false,
    this.allOrders = false,
  });

  final bool salesOnly;
  final bool allOrders;

  @override
  ConsumerState<MerchantOrdersPage> createState() => _MerchantOrdersPageState();
}

class _MerchantOrdersPageState extends ConsumerState<MerchantOrdersPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(merchantProvider.notifier)
          .loadOrders(salesOnly: widget.salesOnly),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(merchantProvider);
    final title = widget.salesOnly
        ? (isAr ? 'سجل البيع' : 'Historique des ventes')
        : widget.allOrders
        ? (isAr ? 'سجل الطلبات' : 'Historique des commandes')
        : (isAr ? 'الطلبات' : 'Commandes');
    final orders = widget.salesOnly || widget.allOrders
        ? state.orders
        : state.orders.where((order) => order.status == 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/merchant'),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text(isAr ? 'لا توجد بيانات' : 'Aucune donnée'))
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(merchantProvider.notifier)
                  .loadOrders(salesOnly: widget.salesOnly),
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: orders.length,
                itemBuilder: (_, index) => _OrderCard(
                  order: orders[index],
                  isAr: isAr,
                  showActions:
                      !widget.salesOnly &&
                      !widget.allOrders &&
                      orders[index].status == 'pending',
                ),
              ),
            ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({
    required this.order,
    required this.isAr,
    required this.showActions,
  });

  final MerchantOrderModel order;
  final bool isAr;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final submitting = ref.watch(merchantProvider).isSubmitting;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProductImage(url: order.imageUrl, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        fmt.format(order.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status, isAr: isAr),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoPill(
                  icon: Icons.person_outline,
                  label: order.buyerName ?? order.clientName ?? '—',
                  color: AppColors.primary,
                ),
                InfoPill(
                  icon: Icons.phone_outlined,
                  label: order.clientPhone ?? '—',
                  color: AppColors.secondary,
                ),
                InfoPill(
                  icon: Icons.numbers_outlined,
                  label: '${isAr ? 'الكمية' : 'Qté'} ${order.quantity}',
                  color: AppColors.success,
                ),
                InfoPill(
                  icon: Icons.payments_outlined,
                  label: '${order.totalPrice.toStringAsFixed(0)} MRU',
                  color: Colors.teal,
                ),
                if (order.paymentPhoneFrom != null)
                  InfoPill(
                    icon: Icons.account_balance_wallet_outlined,
                    label: isAr
                        ? 'دفع من: ${order.paymentPhoneFrom}'
                        : 'Payé depuis: ${order.paymentPhoneFrom}',
                    color: AppColors.warning,
                  ),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${isAr ? 'ملاحظات: ' : 'Remarques: '}${order.notes}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (order.screenshotUrl != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _viewScreenshot(context, order.screenshotUrl!),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.screenshotUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? 'عرض إثبات الدفع' : 'Voir la preuve de paiement',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: submitting
                          ? null
                          : () => _update(context, ref, 'cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: Text(isAr ? 'إلغاء' : 'Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () => _update(context, ref, 'confirmed'),
                      child: Text(isAr ? 'تأكيد' : 'Confirmer'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _viewScreenshot(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    final error = await ref
        .read(merchantProvider.notifier)
        .updateOrderStatus(order.id, status);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? null : AppColors.error,
        content: Text(error ?? (isAr ? 'تم التحديث' : 'Mis à jour')),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isAr});

  final String status;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'confirmed' => (isAr ? 'مؤكد' : 'Confirmée', AppColors.success),
      'delivered' => (isAr ? 'تم التسليم' : 'Livrée', Colors.teal),
      'cancelled' => (isAr ? 'ملغي' : 'Annulée', AppColors.error),
      _ => (isAr ? 'جديد' : 'Nouvelle', AppColors.warning),
    };
    return InfoPill(icon: Icons.circle, label: label, color: color);
  }
}
