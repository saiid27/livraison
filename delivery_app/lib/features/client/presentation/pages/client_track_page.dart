import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/providers/language_provider.dart';

class ClientTrackPage extends ConsumerStatefulWidget {
  final String orderId;
  const ClientTrackPage({super.key, required this.orderId});

  @override
  ConsumerState<ClientTrackPage> createState() => _ClientTrackPageState();
}

class _ClientTrackPageState extends ConsumerState<ClientTrackPage> {
  final int _currentStep = 1;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    final steps = [
      _TrackStep(icon: Icons.receipt_long, title: s.orderReceived, subtitle: s.orderReceivedSub),
      _TrackStep(icon: Icons.person_search, title: s.driverAssigned, subtitle: s.driverAssignedSub),
      _TrackStep(icon: Icons.local_shipping, title: s.onTheWay, subtitle: s.onTheWaySub),
      _TrackStep(icon: Icons.check_circle, title: s.deliveredTitle, subtitle: s.deliveredSub),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.trackOrderPrefix}${widget.orderId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client/orders'),
        ),
        actions: [const LanguageButton(), const LogoutButton()],
      ),
      body: Column(
        children: [
          Container(
            height: 250,
            color: Colors.grey[200],
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.map, size: 80, color: Colors.grey),
                Text(s.mapPlaceholder, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s.live, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                  Text(s.deliveryStatus, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  if (_currentStep >= 1)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: AppColors.primary, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ahmed Mohamed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(s.driver, style: const TextStyle(color: AppColors.textSecondary)),
                                const Row(
                                  children: [
                                    Icon(Icons.star, color: AppColors.secondary, size: 16),
                                    SizedBox(width: 4),
                                    Text('4.8', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: AppColors.success,
                            child: IconButton(
                              icon: const Icon(Icons.phone, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
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

class _TrackStep {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrackStep({required this.icon, required this.title, required this.subtitle});
}

class _TrackStepWidget extends StatelessWidget {
  final _TrackStep step;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  const _TrackStepWidget({required this.step, required this.isDone, required this.isActive, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.success : isActive ? AppColors.primary : AppColors.border;

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
            if (!isLast) Container(width: 2, height: 40, color: isDone ? AppColors.success : AppColors.border),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: TextStyle(fontWeight: FontWeight.w600, color: isActive ? AppColors.primary : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(step.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
