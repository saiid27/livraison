import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/providers/language_provider.dart';
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
    Future.microtask(() => ref.read(orderProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myOrders),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client'),
        ),
        actions: [const LanguageButton(), const LogoutButton()],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.orders.isEmpty
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
              onRefresh: () => ref.read(orderProvider.notifier).loadOrders(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.orders.length,
                itemBuilder: (_, i) {
                  final order = state.orders[i];
                  return _OrderDetailCard(
                    order: order,
                    s: s,
                    onTap: () => context.go('/client/track/${order.id}'),
                    onCancel: order.status == 'en_attente'
                        ? () => _confirmCancel(context, order.id, s)
                        : null,
                  );
                },
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
