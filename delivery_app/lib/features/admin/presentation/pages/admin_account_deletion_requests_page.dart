import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../data/models/account_deletion_request_model.dart';
import '../providers/admin_account_deletion_provider.dart';

class AdminAccountDeletionRequestsPage extends ConsumerStatefulWidget {
  const AdminAccountDeletionRequestsPage({super.key});

  @override
  ConsumerState<AdminAccountDeletionRequestsPage> createState() =>
      _AdminAccountDeletionRequestsPageState();
}

class _AdminAccountDeletionRequestsPageState
    extends ConsumerState<AdminAccountDeletionRequestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  static const _statuses = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _statuses.length, vsync: this);
    Future.microtask(
      () => ref.read(adminAccountDeletionProvider.notifier).loadRequests(),
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
    final state = ref.watch(adminAccountDeletionProvider);
    final labels = isAr
        ? ['في الانتظار', 'تم الحذف', 'مرفوضة']
        : ['En attente', 'Supprimés', 'Refusées'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'طلبات حذف الحسابات' : 'Suppressions de comptes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
        ),
        actions: const [LanguageButton(), LogoutButton()],
        bottom: TabBar(
          controller: _tab,
          tabs: labels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _statuses.map((status) {
          final requests = state.requests
              .where((request) => request.status == status)
              .toList();

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (requests.isEmpty) {
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
                ref.read(adminAccountDeletionProvider.notifier).loadRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: requests.length,
              itemBuilder: (context, index) =>
                  _DeletionRequestCard(request: requests[index], isAr: isAr),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DeletionRequestCard extends ConsumerWidget {
  const _DeletionRequestCard({required this.request, required this.isAr});

  final AccountDeletionRequestModel request;
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final isSubmitting = ref.watch(adminAccountDeletionProvider).isSubmitting;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.userName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                _StatusBadge(status: request.status, isAr: isAr),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: isAr ? 'رقم الهاتف' : 'Téléphone',
              value: request.phone,
            ),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: isAr ? 'نوع الحساب' : 'Rôle',
              value: _roleLabel(request.role, isAr),
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: isAr ? 'تاريخ الطلب' : 'Date',
              value: fmt.format(request.createdAt),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${isAr ? 'السبب: ' : 'Raison : '}${request.reason}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
            if (request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                '${isAr ? 'سبب الرفض: ' : 'Motif du refus : '}${request.rejectionReason}',
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            if (request.status == 'pending') ...[
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
                      ),
                      icon: const Icon(Icons.delete_forever_outlined, size: 16),
                      label: Text(isAr ? 'موافقة وحذف' : 'Approuver'),
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

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حذف الحساب؟' : 'Supprimer le compte ?'),
        content: Text(
          isAr
              ? 'سيتم حذف الحساب بعد الموافقة. هل تريد المتابعة؟'
              : 'Le compte sera supprimé après approbation. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isAr ? 'إلغاء' : 'Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isAr ? 'حذف' : 'Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await ref
        .read(adminAccountDeletionProvider.notifier)
        .approve(request.id);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: error == null ? null : AppColors.error,
        content: Text(error ?? (isAr ? 'تم حذف الحساب' : 'Compte supprimé')),
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _RejectReasonDialog(isAr: isAr),
    );
    if (reason == null) return;
    if (reason.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(isAr ? 'سبب الرفض مطلوب' : 'Motif requis')),
      );
      return;
    }

    final error = await ref
        .read(adminAccountDeletionProvider.notifier)
        .reject(request.id, reason);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: error == null ? null : AppColors.error,
        content: Text(error ?? (isAr ? 'تم رفض الطلب' : 'Demande refusée')),
      ),
    );
  }

  String _roleLabel(String role, bool isAr) {
    return switch (role) {
      'client' => isAr ? 'عميل' : 'Client',
      'livreur' => isAr ? 'مندوب توصيل' : 'Livreur',
      'car_captain' => isAr ? 'كابتن سيارة' : 'Capitaine voiture',
      'merchant' => isAr ? 'تاجر' : 'Commerçant',
      'admin' => isAr ? 'أدمن' : 'Admin',
      _ => role,
    };
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog({required this.isAr});

  final bool isAr;

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;

    return AlertDialog(
      title: Text(isAr ? 'رفض الطلب' : 'Refuser la demande'),
      content: TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: isAr ? 'سبب الرفض' : 'Motif du refus',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isAr ? 'إلغاء' : 'Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(isAr ? 'رفض' : 'Refuser'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
      'approved' => (isAr ? 'تم الحذف' : 'Supprimé', AppColors.success),
      'rejected' => (isAr ? 'مرفوض' : 'Refusé', AppColors.error),
      _ => (isAr ? 'في الانتظار' : 'En attente', AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
