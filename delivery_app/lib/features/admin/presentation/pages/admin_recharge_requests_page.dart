import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../providers/admin_recharge_provider.dart';
import '../../../livreur/data/models/recharge_request_model.dart';

class AdminRechargeRequestsPage extends ConsumerStatefulWidget {
  const AdminRechargeRequestsPage({super.key});

  @override
  ConsumerState<AdminRechargeRequestsPage> createState() =>
      _AdminRechargeRequestsPageState();
}

class _AdminRechargeRequestsPageState
    extends ConsumerState<AdminRechargeRequestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _tabs = ['en_attente', 'verifie', 'refuse'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    Future.microtask(
      () => ref.read(adminRechargeProvider.notifier).loadRequests(),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(adminRechargeProvider);

    final tabLabels = isAr
        ? ['في الانتظار', 'تم التحقق', 'مرفوضة']
        : ['En attente', 'Vérifiées', 'Refusées'];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'طلبات الشحن' : 'Demandes de recharge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
        ),
        actions: const [LanguageButton(), LogoutButton()],
        bottom: TabBar(
          controller: _tab,
          tabs: tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _tabs.map((status) {
          final filtered = state.requests
              .where((r) => r.status == status)
              .toList();

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 60,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAr ? 'لا توجد طلبات' : 'Aucune demande',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(adminRechargeProvider.notifier).loadRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: filtered.length,
              itemBuilder: (_, i) =>
                  _RequestCard(request: filtered[i], isAr: isAr),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends ConsumerWidget {
  final RechargeRequestModel request;
  final bool isAr;

  const _RequestCard({required this.request, required this.isAr});

  String get _imageBase => AppConstants.baseUrl.replaceAll('/api', '');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final isSubmitting = ref.watch(adminRechargeProvider).isSubmitting;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request.captainName ?? '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                _StatusBadge(status: request.status, isAr: isAr),
              ],
            ),
            const SizedBox(height: 10),

            // Details
            _Row(
              icon: Icons.monetization_on_rounded,
              label: isAr ? 'المبلغ' : 'Montant',
              value:
                  '${request.amount.toStringAsFixed(0)} ${isAr ? 'أوقية' : 'MRU'}',
              bold: true,
            ),
            _Row(
              icon: Icons.payment_rounded,
              label: isAr ? 'طريقة الدفع' : 'Moyen',
              value: request.paymentMethodName ?? '—',
            ),
            _Row(
              icon: Icons.phone_rounded,
              label: isAr ? 'الهاتف المرسِل' : 'Téléphone émetteur',
              value: request.phoneFrom,
            ),
            _Row(
              icon: Icons.calendar_today_rounded,
              label: isAr ? 'التاريخ' : 'Date',
              value: fmt.format(request.createdAt),
            ),

            if (request.status == 'refuse' && request.rejectionReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${isAr ? 'السبب: ' : 'Motif : '}${request.rejectionReason}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Screenshot
            if (request.screenshotUrl != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showScreenshot(context, request.screenshotUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    '$_imageBase${request.screenshotUrl}',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 80,
                      color: AppColors.surface,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Action buttons — only for en_attente
            if (request.status == 'en_attente') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () => _showRejectDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(isAr ? 'رفض' : 'Refuser'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () => _approve(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(isAr ? 'موافقة' : 'Approuver'),
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

  void _showScreenshot(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network('$_imageBase$url', fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final err = await ref
        .read(adminRechargeProvider.notifier)
        .approveRequest(request.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? (isAr ? 'تمت الموافقة' : 'Demande approuvée')),
        backgroundColor: err != null ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'سبب الرفض' : 'Motif de refus'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: isAr ? 'اكتب السبب هنا...' : 'Écrivez le motif ici...',
            ),
            validator: (v) => (v?.trim().isEmpty ?? true)
                ? (isAr ? 'مطلوب' : 'Obligatoire')
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? 'إلغاء' : 'Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(isAr ? 'رفض' : 'Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final err = await ref
        .read(adminRechargeProvider.notifier)
        .rejectRequest(request.id, ctrl.text.trim());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? (isAr ? 'تم الرفض' : 'Demande refusée')),
        backgroundColor: err != null ? AppColors.error : AppColors.success,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool bold;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label : ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isAr;

  const _StatusBadge({required this.status, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'verifie' => (isAr ? 'تم التحقق' : 'Vérifié', AppColors.success),
      'refuse' => (isAr ? 'مرفوض' : 'Refusé', AppColors.error),
      _ => (isAr ? 'في الانتظار' : 'En attente', AppColors.warning),
    };

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
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
