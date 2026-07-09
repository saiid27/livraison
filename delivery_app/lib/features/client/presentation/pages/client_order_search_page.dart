import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';

const int _maxAttempts = 5;
const int _broadcastDuration = 60;
const int _pauseDuration = 10;

class ClientOrderSearchPage extends ConsumerStatefulWidget {
  final String orderId;
  const ClientOrderSearchPage({super.key, required this.orderId});

  @override
  ConsumerState<ClientOrderSearchPage> createState() =>
      _ClientOrderSearchPageState();
}

class _ClientOrderSearchPageState extends ConsumerState<ClientOrderSearchPage>
    with TickerProviderStateMixin {
  Timer? _pollTimer;
  late AnimationController _pulseController;

  // Broadcast state (server-driven)
  int _attempt = 1;
  bool _broadcasting = true;
  int _secondsRemaining = _broadcastDuration;
  bool _expired = false;

  // Order accepted state
  bool _accepted = false;
  String? _captainName;
  String? _captainPhone;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pollOrder();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollOrder(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pollOrder() async {
    try {
      final response = await ApiClient.instance.get(
        '/client/orders/${widget.orderId}',
      );
      final data = response.data['order'] as Map<String, dynamic>;
      final status = data['status'] as String;

      if (!mounted) return;

      if (status == 'en_cours' || status == 'livre') {
        _pollTimer?.cancel();
        setState(() {
          _accepted = true;
          _captainName = data['livreur_name'] as String?;
          _captainPhone = data['livreur_phone'] as String?;
        });
        return;
      }

      if (status == 'annule') {
        _pollTimer?.cancel();
        if (mounted) context.go('/client/orders');
        return;
      }

      // Still en_attente — update broadcast state
      final broadcast = data['broadcast'] as Map<String, dynamic>?;
      if (broadcast != null) {
        setState(() {
          _expired = broadcast['expired'] as bool;
          _attempt = broadcast['attempt'] as int;
          _broadcasting = broadcast['broadcasting'] as bool;
          _secondsRemaining = broadcast['seconds_remaining'] as int;
        });
        if (_expired) _pollTimer?.cancel();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'البحث عن كابتن' : 'Recherche d\'un capitaine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/client/orders'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _accepted
              ? _CaptainFoundView(
                  isAr: isAr,
                  captainName: _captainName,
                  captainPhone: _captainPhone,
                  orderId: widget.orderId,
                )
              : _expired
              ? _ExpiredView(isAr: isAr)
              : _SearchingView(
                  isAr: isAr,
                  attempt: _attempt,
                  broadcasting: _broadcasting,
                  secondsRemaining: _secondsRemaining,
                  pulseController: _pulseController,
                ),
        ),
      ),
    );
  }
}

// ── Searching view ────────────────────────────────────────────────────────────

class _SearchingView extends StatelessWidget {
  final bool isAr;
  final int attempt;
  final bool broadcasting;
  final int secondsRemaining;
  final AnimationController pulseController;

  const _SearchingView({
    required this.isAr,
    required this.attempt,
    required this.broadcasting,
    required this.secondsRemaining,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Animated pulse icon
        Center(
          child: AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 0.85 + pulseController.value * 0.15;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: broadcasting
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    broadcasting
                        ? Icons.delivery_dining_rounded
                        : Icons.pause_circle_outline_rounded,
                    size: 64,
                    color: broadcasting ? AppColors.primary : AppColors.warning,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),

        Text(
          broadcasting
              ? (isAr
                    ? 'جارٍ البحث عن كابتن...'
                    : 'Recherche d\'un capitaine...')
              : (isAr
                    ? 'توقف مؤقت قبل المحاولة التالية'
                    : 'Pause avant la prochaine tentative'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: broadcasting ? AppColors.textPrimary : AppColors.warning,
          ),
        ),
        const SizedBox(height: 12),

        // Attempt counter
        Text(
          isAr
              ? 'المحاولة $attempt من $_maxAttempts'
              : 'Tentative $attempt / $_maxAttempts',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // Countdown circle
        Center(
          child: _CountdownCircle(
            seconds: secondsRemaining,
            total: broadcasting ? _broadcastDuration : _pauseDuration,
            color: broadcasting ? AppColors.primary : AppColors.warning,
          ),
        ),
        const SizedBox(height: 32),

        // Attempt progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_maxAttempts, (i) {
            final done = i < attempt - 1;
            final active = i == attempt - 1;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 10,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: done
                    ? AppColors.success
                    : active
                    ? AppColors.primary
                    : AppColors.border,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CountdownCircle extends StatelessWidget {
  final int seconds;
  final int total;
  final Color color;

  const _CountdownCircle({
    required this.seconds,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? seconds / total : 0.0;
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '$seconds',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expired view ──────────────────────────────────────────────────────────────

class _ExpiredView extends StatelessWidget {
  final bool isAr;
  const _ExpiredView({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(
            Icons.sentiment_dissatisfied_rounded,
            size: 96,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          isAr
              ? 'لا يوجد حالياً أي كابتن متاح بالقرب من موقعك.\nيرجى التواصل مع الشركة.'
              : 'Aucun capitaine n\'est actuellement disponible à proximité de votre position.\nVeuillez contacter la société.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        ElevatedButton.icon(
          onPressed: () => context.go('/client/orders'),
          icon: const Icon(Icons.receipt_long_outlined),
          label: Text(isAr ? 'عرض طلباتي' : 'Voir mes commandes'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}

// ── Captain found view ────────────────────────────────────────────────────────

class _CaptainFoundView extends StatelessWidget {
  final bool isAr;
  final String? captainName;
  final String? captainPhone;
  final String orderId;

  const _CaptainFoundView({
    required this.isAr,
    required this.captainName,
    required this.captainPhone,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(
            Icons.check_circle_rounded,
            size: 96,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isAr ? 'تم العثور على كابتن !' : 'Capitaine trouvé !',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 28),

        // Captain info card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
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
                      captainName ?? (isAr ? 'الكابتن' : 'Capitaine'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (captainPhone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            captainPhone!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
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
        ),

        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: () => context.go('/client/track/$orderId'),
          icon: const Icon(Icons.location_on_rounded),
          label: Text(isAr ? 'تتبع الطلب' : 'Suivre la commande'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => context.go('/client/orders'),
          child: Text(
            isAr ? 'عودة إلى طلباتي' : 'Retour à mes commandes',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
