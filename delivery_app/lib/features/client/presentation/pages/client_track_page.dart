import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/providers/language_provider.dart';
import '../../data/models/order_model.dart';

class ClientTrackPage extends ConsumerStatefulWidget {
  final String orderId;
  const ClientTrackPage({super.key, required this.orderId});

  @override
  ConsumerState<ClientTrackPage> createState() => _ClientTrackPageState();
}

class _ClientTrackPageState extends ConsumerState<ClientTrackPage> {
  OrderModel? _order;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadOrder(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      final response = await ApiClient.instance.get(
        '/client/orders/${widget.orderId}',
      );
      final order = OrderModel.fromJson(
        response.data['order'] as Map<String, dynamic>,
      );
      if (mounted) setState(() => _order = order);
      if (order.status == 'livre') _refreshTimer?.cancel();
    } catch (_) {}
  }

  int get _currentStep {
    return switch (_order?.status) {
      'en_cours' => 2,
      'livre' => 3,
      _ => 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final steps = [
      _TrackStep(
        icon: Icons.receipt_long,
        title: s.orderReceived,
        subtitle: s.orderReceivedSub,
      ),
      _TrackStep(
        icon: Icons.person_search,
        title: s.driverAssigned,
        subtitle: s.driverAssignedSub,
      ),
      _TrackStep(
        icon: Icons.local_shipping,
        title: s.onTheWay,
        subtitle: s.onTheWaySub,
      ),
      _TrackStep(
        icon: Icons.check_circle,
        title: s.deliveredTitle,
        subtitle: s.deliveredSub,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.trackOrderPrefix}${widget.orderId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/client/orders'),
        ),
        actions: [const LanguageButton(), const LogoutButton()],
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            color: Colors.grey[200],
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.map, size: 80, color: Colors.grey),
                Text(
                  s.mapPlaceholder,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.live,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.deliveryStatus,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(steps.length, (i) {
                    final step = steps[i];
                    return _TrackStepWidget(
                      step: step,
                      isDone: i < _currentStep,
                      isActive: i == _currentStep,
                      isLast: i == steps.length - 1,
                    );
                  }),
                  const SizedBox(height: 24),

                  // Captain info card (real data)
                  if (_order?.livreurName != null ||
                      _order?.livreurPhone != null)
                    _CaptainCard(
                      isAr: isAr,
                      name: _order?.livreurName,
                      phone: _order?.livreurPhone,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptainCard extends StatelessWidget {
  final bool isAr;
  final String? name;
  final String? phone;

  const _CaptainCard({required this.isAr, this.name, this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? (isAr ? 'الكابتن' : 'Capitaine'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isAr ? 'كابتن توصيل' : 'Capitaine de livraison',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (phone != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        phone!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackStep {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrackStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _TrackStepWidget extends StatelessWidget {
  final _TrackStep step;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  const _TrackStepWidget({
    required this.step,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? AppColors.success
        : isActive
        ? AppColors.primary
        : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDone || isActive ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                isDone ? Icons.check : step.icon,
                size: 20,
                color: isDone || isActive ? Colors.white : color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDone ? AppColors.success : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
