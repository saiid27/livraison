import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/providers/language_provider.dart';
import '../providers/admin_provider.dart';

class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  String _filter = 'tous';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final s = ref.watch(stringsProvider);
    final filtered = _filter == 'tous'
        ? state.orders
        : state.orders.where((o) => o.status == _filter).toList();

    final filters = [
      (label: s.allLabel, value: 'tous'),
      (label: s.pending, value: 'en_attente'),
      (label: s.activeLabel, value: 'en_cours'),
      (label: s.deliveredCount, value: 'livre'),
      (label: s.cancelledCount, value: 'annule'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navOrders),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
        ),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: filters
                  .map(
                    (f) => _FilterChip(
                      label: f.label,
                      selected: _filter == f.value,
                      onTap: () => setState(() => _filter = f.value),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      s.noOrders,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(adminProvider.notifier).loadOrders(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final order = filtered[i];
                        return _AdminOrderCard(
                          order: order,
                          s: s,
                          onStatusChange: (status) => ref
                              .read(adminProvider.notifier)
                              .updateOrderStatus(order.id, status),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final dynamic order;
  final dynamic s;
  final void Function(String) onStatusChange;

  const _AdminOrderCard({
    required this.order,
    required this.s,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    fontSize: 15,
                  ),
                ),
                if (order.price != null)
                  Text(
                    '${order.price!.toStringAsFixed(0)} ${s.currency}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.pickupAddress,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (order.clientName != null || order.clientPhone != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [
                        if (order.clientName != null &&
                            order.clientName!.isNotEmpty)
                          order.clientName!,
                        if (order.clientPhone != null &&
                            order.clientPhone!.isNotEmpty)
                          order.clientPhone!,
                      ].join(' - '),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.flag, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${s.statusLabel}: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                DropdownButton<String>(
                  value: order.status,
                  isDense: true,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(
                      value: 'en_attente',
                      child: Text(s.statusWaiting),
                    ),
                    DropdownMenuItem(
                      value: 'en_cours',
                      child: Text(s.statusInProgress),
                    ),
                    DropdownMenuItem(
                      value: 'livre',
                      child: Text(s.statusDelivered),
                    ),
                    DropdownMenuItem(
                      value: 'annule',
                      child: Text(s.statusCancelled),
                    ),
                  ],
                  onChanged: (v) => v != null ? onStatusChange(v) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
