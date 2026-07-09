import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../client/data/models/order_model.dart';
import '../providers/livreur_provider.dart';

class LivreurHistoryPage extends ConsumerStatefulWidget {
  final String baseRoute;

  const LivreurHistoryPage({super.key, this.baseRoute = '/livreur'});

  @override
  ConsumerState<LivreurHistoryPage> createState() => _LivreurHistoryPageState();
}

class _LivreurHistoryPageState extends ConsumerState<LivreurHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() => ref.read(livreurProvider.notifier).loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final s = ref.watch(stringsProvider);
    final state = ref.watch(livreurProvider);

    final all = state.myOrders;
    final inProgress = all.where((o) => o.status == 'en_cours').toList();
    final delivered = all.where((o) => o.status == 'livre').toList();
    final cancelled = all.where((o) => o.status == 'annule').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'سجل الطلبات' : 'Historique des demandes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(widget.baseRoute),
        ),
        actions: const [LanguageButton(), LogoutButton()],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [
            Tab(text: isAr ? s.historyAll : s.historyAll),
            Tab(text: isAr ? s.historyInProgress : s.historyInProgress),
            Tab(text: isAr ? s.historyDelivered : s.historyDelivered),
            Tab(text: isAr ? s.historyCancelled : s.historyCancelled),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _OrderList(orders: all, isAr: isAr, s: s),
                _OrderList(orders: inProgress, isAr: isAr, s: s),
                _OrderList(orders: delivered, isAr: isAr, s: s),
                _OrderList(orders: cancelled, isAr: isAr, s: s),
              ],
            ),
    );
  }
}

// ── Order list ────────────────────────────────────────────────────────────────

class _OrderList extends ConsumerWidget {
  final List<OrderModel> orders;
  final bool isAr;
  final dynamic s;

  const _OrderList({required this.orders, required this.isAr, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'لا توجد طلبات في هذه الفئة'
                  : 'Aucune demande dans cette catégorie',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(livreurProvider.notifier).loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) =>
            _HistoryOrderCard(order: orders[i], isAr: isAr, s: s),
      ),
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────

class _HistoryOrderCard extends ConsumerWidget {
  final OrderModel order;
  final bool isAr;
  final dynamic s;

  const _HistoryOrderCard({
    required this.order,
    required this.isAr,
    required this.s,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final (label, color) = _statusInfo(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
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
                _Badge(label: label, color: color),
              ],
            ),
            const Divider(height: 18),

            // Addresses
            _InfoRow(
              icon: Icons.radio_button_checked,
              color: AppColors.success,
              text: order.pickupAddress,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.location_on_rounded,
              color: AppColors.error,
              text: order.deliveryAddress,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
              text: order.description,
            ),
            if (order.clientPhone != null && order.clientPhone!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.phone_outlined,
                color: AppColors.success,
                text: order.clientPhone!,
              ),
            ],

            const Divider(height: 18),

            // Footer row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fmt.format(order.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (order.price != null)
                  Text(
                    '${order.price!.toStringAsFixed(0)} ${isAr ? 'أوقية' : 'MRU'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
              ],
            ),

            // Cancellation reason (if any)
            if (order.cancellationReason != null &&
                order.cancellationReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'سبب الإلغاء' : 'Motif d\'annulation',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.cancellationReason!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Cancel button for en_cours orders
            if (order.status == 'en_cours') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => order.pickedUpAt == null
                      ? _confirmPickup(context, ref)
                      : _confirmDelivery(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.pickedUpAt == null
                        ? AppColors.primary
                        : AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    order.pickedUpAt == null
                        ? Icons.inventory_2_outlined
                        : Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    order.pickedUpAt == null
                        ? (isAr ? 'استلمت الرسالة' : 'Message récupéré')
                        : (isAr ? 'تم التوصيل' : 'Livraison terminée'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (order.pickedUpAt == null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(
                      isAr ? 'إلغاء التوصيل' : 'Annuler la livraison',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPickup(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isAr ? 'تأكيد الاستلام' : 'Confirmer la récupération'),
        content: Text(
          isAr
              ? 'هل أخذت الرسالة من الزبون؟ بعد التأكيد سيظهر لك زر تم التوصيل.'
              : 'Avez-vous récupéré le message ? Le bouton de livraison apparaîtra ensuite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(isAr ? 'لا' : 'Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(isAr ? 'نعم، استلمت' : 'Oui, récupéré'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final error = await ref
        .read(livreurProvider.notifier)
        .confirmPickup(order.id);
    if (!context.mounted) return;
    final message = error == null
        ? (isAr ? 'تم تأكيد الاستلام' : 'Récupération confirmée')
        : error == 'insufficient_balance'
        ? (isAr
              ? 'رصيدك غير كافٍ لاستلام الرسالة'
              : 'Solde insuffisant pour récupérer le message')
        : error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _confirmDelivery(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isAr ? 'تأكيد التوصيل' : 'Confirmer la livraison'),
        content: Text(
          isAr
              ? 'هل وصلت الرسالة للزبون؟ عند التأكيد ينتهي الطلب ويختفي من الطلبات الجارية.'
              : 'Le message a-t-il été livré ? La commande sera terminée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(isAr ? 'لا' : 'Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(isAr ? 'نعم، تم التوصيل' : 'Oui, livré'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final success = await ref
        .read(livreurProvider.notifier)
        .updateStatus(order.id, 'livre');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (isAr ? 'تم إنهاء الطلب' : 'Commande terminée')
              : (isAr ? 'حدث خطأ' : 'Une erreur est survenue'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'إلغاء التوصيل' : 'Annuler la livraison',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? 'يرجى كتابة سبب الإلغاء قبل التأكيد.'
                      : 'Veuillez indiquer le motif d\'annulation avant de confirmer.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: isAr ? 'سبب الإلغاء' : 'Motif d\'annulation',
                    hintText: isAr
                        ? 'اكتب سبب إلغاء هذا التوصيل...'
                        : 'Expliquez pourquoi vous annulez...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isAr ? 'السبب مطلوب' : 'Le motif est obligatoire';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting
                  ? null
                  : () => Navigator.of(dialogCtx).pop(),
              child: Text(
                isAr ? 'تراجع' : 'Annuler',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      final ok = await ref
                          .read(livreurProvider.notifier)
                          .cancelOrder(order.id, reasonCtrl.text.trim());
                      if (!dialogCtx.mounted) return;
                      Navigator.of(dialogCtx).pop();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? (isAr
                                      ? 'تم إلغاء التوصيل'
                                      : 'Livraison annulée')
                                : (isAr
                                      ? 'حدث خطأ'
                                      : 'Une erreur est survenue'),
                          ),
                          backgroundColor: ok
                              ? AppColors.warning
                              : AppColors.error,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isAr ? 'تأكيد الإلغاء' : 'Confirmer l\'annulation'),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusInfo(String status) => switch (status) {
    'en_cours' => (
      order.pickedUpAt == null
          ? (isAr ? 'بانتظار الاستلام' : 'À récupérer')
          : (isAr ? 'بانتظار التوصيل' : 'À livrer'),
      AppColors.primary,
    ),
    'livre' => (isAr ? 'مُوصَّل' : 'Livré', AppColors.success),
    'annule' => (isAr ? 'ملغي' : 'Annulé', AppColors.error),
    _ => (status, AppColors.textSecondary),
  };
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
