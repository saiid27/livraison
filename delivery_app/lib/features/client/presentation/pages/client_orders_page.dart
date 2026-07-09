import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../merchant/data/models/merchant_order_model.dart';
import '../../../merchant/presentation/widgets/merchant_widgets.dart';
import '../providers/marketplace_provider.dart';
import '../providers/order_provider.dart';
import 'package:intl/intl.dart';

class ClientOrdersPage extends ConsumerStatefulWidget {
  const ClientOrdersPage({super.key});

  @override
  ConsumerState<ClientOrdersPage> createState() => _ClientOrdersPageState();
}

class _ClientOrdersPageState extends ConsumerState<ClientOrdersPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadOrders);
  }

  Future<void> _loadOrders() async {
    await Future.wait([
      ref.read(orderProvider.notifier).loadOrders(),
      ref.read(marketplaceProvider.notifier).loadOrders(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final marketplaceState = ref.watch(marketplaceProvider);
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final isLoading = state.isLoading || marketplaceState.isLoading;
    final deliveryOrders = state.orders;
    final productOrders = marketplaceState.orders;
    final hasOrders = deliveryOrders.isNotEmpty || productOrders.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myOrders),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/client'),
        ),
        actions: [const LanguageButton(), const LogoutButton()],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasOrders
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.noOrders,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/client/new-order'),
                    icon: const Icon(Icons.add),
                    label: Text(s.orderNow),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (deliveryOrders.isNotEmpty) ...[
                    _SectionTitle(
                      title: isAr ? 'طلبات التوصيل' : 'Commandes livraison',
                    ),
                    const SizedBox(height: 8),
                    for (final order in deliveryOrders)
                      _OrderDetailCard(
                        order: order,
                        s: s,
                        onTap: () => context.go('/client/track/${order.id}'),
                        onCancel: order.status == 'en_attente'
                            ? () => _confirmCancel(context, order.id, s)
                            : null,
                      ),
                  ],
                  if (productOrders.isNotEmpty) ...[
                    if (deliveryOrders.isNotEmpty) const SizedBox(height: 10),
                    _SectionTitle(
                      title: isAr ? 'طلبات المنتجات' : 'Commandes produits',
                    ),
                    const SizedBox(height: 8),
                    for (final order in productOrders)
                      _ProductOrderCard(order: order, isAr: isAr),
                  ],
                ],
              ),
            ),
    );
  }

  void _confirmCancel(BuildContext context, String orderId, s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.cancelOrderTitle),
        content: Text(s.cancelOrderConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.no)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(orderProvider.notifier).cancelOrder(orderId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(s.cancelOrder),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _OrderDetailCard extends StatelessWidget {
  final dynamic order;
  final dynamic s;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _OrderDetailCard({
    required this.order,
    required this.s,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final (statusLabel, statusColor) = _statusInfo(order.status, s);
    final isAr = Directionality.of(context) == ui.TextDirection.rtl;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '# ${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _Badge(label: statusLabel, color: statusColor),
                ],
              ),
              const Divider(height: 20),
              _InfoRow(
                icon: order.serviceType == 'course'
                    ? Icons.directions_car_outlined
                    : Icons.inventory_2_outlined,
                text: order.serviceType == 'course'
                    ? '${order.description} • ${isAr ? 'كورس' : 'Course'}'
                    : order.description,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.location_on,
                text: order.pickupAddress,
                color: AppColors.primary,
              ),
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.flag,
                text: order.deliveryAddress,
                color: AppColors.success,
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(order.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (order.price != null)
                    Text(
                      '${order.price!.toStringAsFixed(0)} ${s.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
              if (order.livreurName != null) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.person,
                  text: '${s.driver}: ${order.livreurName}',
                ),
              ],
              if (onCancel != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: Text(s.cancelOrder),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _statusInfo(String status, s) => switch (status) {
    'en_attente' => (s.statusWaiting as String, AppColors.warning),
    'en_cours' => (s.statusInProgress as String, AppColors.primary),
    'livre' => (s.statusDelivered as String, AppColors.success),
    'annule' => (s.statusCancelled as String, AppColors.error),
    _ => (status, AppColors.textSecondary),
  };
}

class _ProductOrderCard extends StatelessWidget {
  const _ProductOrderCard({required this.order, required this.isAr});

  final MerchantOrderModel order;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final (statusLabel, statusColor) = _productStatusInfo(order.status, isAr);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProductImage(url: order.imageUrl, size: 66),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        order.merchantName ?? (isAr ? 'التاجر' : 'Boutique'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _Badge(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoPill(
                  icon: Icons.numbers_outlined,
                  label: '${isAr ? 'الكمية' : 'Qté'} ${order.quantity}',
                  color: AppColors.warning,
                ),
                InfoPill(
                  icon: Icons.payments_outlined,
                  label: '${order.totalPrice.toStringAsFixed(0)} MRU',
                  color: Colors.teal,
                ),
                if (order.paymentPhoneFrom != null)
                  InfoPill(
                    icon: Icons.phone_iphone_outlined,
                    label: isAr
                        ? 'دفع من ${order.paymentPhoneFrom}'
                        : 'Payé depuis ${order.paymentPhoneFrom}',
                    color: AppColors.primary,
                  ),
              ],
            ),
            const Divider(height: 22),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: dateFormat.format(order.createdAt),
            ),
            if (order.merchantContactPhone != null &&
                order.merchantContactPhone!.isNotEmpty) ...[
              const SizedBox(height: 7),
              _InfoRow(
                icon: Icons.support_agent_outlined,
                text: isAr
                    ? 'رقم التاجر: ${order.merchantContactPhone}'
                    : 'Contact commerçant: ${order.merchantContactPhone}',
                color: AppColors.primary,
              ),
            ],
            if (order.screenshotUrl != null) ...[
              const SizedBox(height: 7),
              _InfoRow(
                icon: Icons.image_outlined,
                text: isAr
                    ? 'تم إرفاق صورة الدفع'
                    : 'Preuve de paiement jointe',
                color: AppColors.success,
              ),
            ],
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 7),
              _InfoRow(icon: Icons.notes_outlined, text: order.notes!),
            ],
          ],
        ),
      ),
    );
  }

  (String, Color) _productStatusInfo(String status, bool isAr) =>
      switch (status) {
        'confirmed' => (isAr ? 'مؤكد' : 'Confirmée', AppColors.success),
        'delivered' => (isAr ? 'تم التسليم' : 'Livrée', Colors.teal),
        'cancelled' => (isAr ? 'ملغي' : 'Annulée', AppColors.error),
        _ => (isAr ? 'قيد المراجعة' : 'En attente', AppColors.warning),
      };
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
