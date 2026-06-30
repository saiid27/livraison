import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/livreur_provider.dart';

class LivreurHomePage extends ConsumerStatefulWidget {
  const LivreurHomePage({super.key});

  @override
  ConsumerState<LivreurHomePage> createState() => _LivreurHomePageState();
}

class _LivreurHomePageState extends ConsumerState<LivreurHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _seenOrderIds = <String>{};
  Timer? _ordersTimer;
  bool _isPolling = false;
  bool _dialogOpen = false;

  static const _nouakchott = LatLng(18.0735, -15.9582);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(livreurProvider).isOnline) _startPolling();
    });
  }

  @override
  void dispose() {
    _ordersTimer?.cancel();
    super.dispose();
  }

  void _toggleOnline() {
    final willBeOnline = !ref.read(livreurProvider).isOnline;
    ref.read(livreurProvider.notifier).toggleOnline();
    if (willBeOnline) {
      _startPolling();
    } else {
      _ordersTimer?.cancel();
    }
  }

  void _startPolling() {
    _ordersTimer?.cancel();
    unawaited(_pollForOrders());
    _ordersTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollForOrders(),
    );
  }

  Future<void> _pollForOrders() async {
    if (_isPolling || !mounted || !ref.read(livreurProvider).isOnline) return;
    _isPolling = true;
    await ref.read(livreurProvider.notifier).loadData();
    _isPolling = false;
    if (!mounted || _dialogOpen) return;

    final incoming = ref
        .read(livreurProvider)
        .availableOrders
        .where((order) => !_seenOrderIds.contains(order.id))
        .toList();
    if (incoming.isEmpty) return;

    final order = incoming.first;
    _seenOrderIds.add(order.id);
    await _showIncomingOrder(order);
  }

  Future<void> _showIncomingOrder(dynamic order) async {
    if (!mounted) return;
    _dialogOpen = true;
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    final isAr = ref.read(localeProvider).languageCode == 'ar';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var accepting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => _IncomingOrderDialog(
            order: order,
            isAr: isAr,
            isAccepting: accepting,
            onDecline: () => Navigator.of(dialogContext).pop(),
            onAccept: () async {
              setDialogState(() => accepting = true);
              final errorCode = await ref
                  .read(livreurProvider.notifier)
                  .acceptOrder(order.id);
              if (!dialogContext.mounted) return;
              if (errorCode == null) {
                final messenger = ScaffoldMessenger.of(dialogContext);
                Navigator.of(dialogContext).pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(isAr ? 'تم قبول الطلب' : 'Commande acceptée'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                setDialogState(() => accepting = false);
                final msg = errorCode == 'insufficient_balance'
                    ? (isAr
                        ? 'رصيدك غير كافٍ لقبول هذا الطلب'
                        : 'Solde insuffisant pour accepter cette commande')
                    : (isAr
                        ? 'تم أخذ الطلب من كابتن آخر'
                        : 'Commande déjà prise par un autre capitaine');
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        );
      },
    );
    _dialogOpen = false;
    if (mounted && ref.read(livreurProvider).isOnline) {
      unawaited(_pollForOrders());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final user = ref.watch(authProvider).user;
    final state = ref.watch(livreurProvider);

    void comingSoon() {
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'سيتم تفعيل هذا القسم لاحقًا'
                : 'Section disponible prochainement',
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _CaptainDrawer(
        isArabic: isAr,
        userName: user?.name ?? (isAr ? 'كابتن التوصيل' : 'Capitaine'),
        onProfile: () {
          Navigator.of(context).pop();
          context.go('/livreur/profile');
        },
        onWallet: () {
        Navigator.of(context).pop();
        context.go('/livreur/wallet');
      },
      onComingSoon: comingSoon,
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? (isAr ? 'كابتن التوصيل' : 'Capitaine'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              isAr ? 'كابتن توصيل' : 'Capitaine de livraison',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: _nouakchott,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    '${AppConstants.baseUrl}/map/tiles/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.delivery.delivery_app',
              ),
              const MarkerLayer(
                markers: [
                  Marker(
                    point: _nouakchott,
                    width: 54,
                    height: 54,
                    child: _CaptainMapMarker(),
                  ),
                ],
              ),
            ],
          ),
          PositionedDirectional(
            top: 14,
            start: 14,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              elevation: 3,
              child: InkWell(
                onTap: _toggleOnline,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: state.isOnline
                              ? AppColors.success
                              : AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        state.isOnline
                            ? (isAr ? 'متصل' : 'En ligne')
                            : (isAr ? 'غير متصل' : 'Hors ligne'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 8,
            bottom: 4,
            child: Text(
              '© OpenStreetMap',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                backgroundColor: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingOrderDialog extends StatelessWidget {
  final dynamic order;
  final bool isAr;
  final bool isAccepting;
  final VoidCallback onDecline;
  final Future<void> Function() onAccept;

  const _IncomingOrderDialog({
    required this.order,
    required this.isAr,
    required this.isAccepting,
    required this.onDecline,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final isCourse = order.serviceType == 'course';
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: isAccepting ? null : onDecline,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isAr ? 'طلب جديد' : 'Nouvelle demande',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      isCourse
                          ? (isAr ? 'طلب كورس' : 'Course')
                          : (isAr ? 'خدمة توصيل' : 'Livraison'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.clientName ?? (isAr ? 'زبون' : 'Client'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (order.price != null)
                  Text(
                    '${order.price!.toStringAsFixed(0)} MRU',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const Divider(height: 28),
            _RequestInfoRow(
              icon: Icons.radio_button_checked,
              color: AppColors.success,
              label: isAr ? 'نقطة الاستلام' : 'Point de départ',
              value: order.pickupAddress,
            ),
            const SizedBox(height: 14),
            _RequestInfoRow(
              icon: Icons.location_on_rounded,
              color: AppColors.error,
              label: isAr ? 'نقطة الوصول' : 'Destination',
              value: order.deliveryAddress,
            ),
            const SizedBox(height: 14),
            _RequestInfoRow(
              icon: isCourse
                  ? Icons.directions_car_outlined
                  : Icons.inventory_2_outlined,
              color: AppColors.primary,
              label: isAr ? 'التفاصيل' : 'Détails',
              value: order.description,
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: isAccepting ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size.fromHeight(54),
              ),
              icon: isAccepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(isAr ? 'قبول الطلب' : 'Accepter'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isAccepting ? null : onDecline,
              child: Text(
                isAr ? 'رفض' : 'Refuser',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _RequestInfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CaptainMapMarker extends StatelessWidget {
  const _CaptainMapMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
    );
  }
}

class _CaptainDrawer extends StatelessWidget {
  final bool isArabic;
  final String userName;
  final VoidCallback onProfile;
  final VoidCallback onWallet;
  final VoidCallback onComingSoon;

  const _CaptainDrawer({
    required this.isArabic,
    required this.userName,
    required this.onProfile,
    required this.onWallet,
    required this.onComingSoon,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _CaptainMenuItem(
        isArabic ? 'ملفي الشخصي' : 'Mon profil',
        Icons.person_outline_rounded,
        onProfile,
      ),
      _CaptainMenuItem(
        isArabic ? 'محفظتي' : 'Mon portefeuille',
        Icons.account_balance_wallet_outlined,
        onWallet,
      ),
      _CaptainMenuItem(
        isArabic ? 'سجل الرسائل' : 'Messages',
        Icons.chat_bubble_outline_rounded,
        onComingSoon,
      ),
      _CaptainMenuItem(
        isArabic ? 'سجل المعاملات' : 'Transactions',
        Icons.receipt_long_outlined,
        onComingSoon,
      ),
    ];

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.78,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.delivery_dining_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isArabic ? 'كابتن توصيل' : 'Capitaine de livraison',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => ListTile(
                onTap: item.onTap,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: AppColors.primary),
                ),
                title: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptainMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CaptainMenuItem(this.label, this.icon, this.onTap);
}
