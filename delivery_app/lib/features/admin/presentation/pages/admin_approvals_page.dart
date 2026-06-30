import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../providers/admin_provider.dart';

class AdminApprovalsPage extends ConsumerStatefulWidget {
  const AdminApprovalsPage({super.key});

  @override
  ConsumerState<AdminApprovalsPage> createState() => _AdminApprovalsPageState();
}

class _AdminApprovalsPageState extends ConsumerState<AdminApprovalsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminProvider.notifier).loadPendingCaptains(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'طلبات إنشاء الحساب' : 'Demandes de comptes'),
        leading: IconButton(
          onPressed: () => context.go('/admin'),
          icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.users.isEmpty
          ? _EmptyApprovals(isArabic: isAr)
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(adminProvider.notifier).loadPendingCaptains(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.users.length,
                itemBuilder: (context, index) => _CaptainApprovalCard(
                  captain: state.users[index],
                  isArabic: isAr,
                  onDecision: (status) => ref
                      .read(adminProvider.notifier)
                      .updateCaptainApproval(state.users[index].id, status),
                ),
              ),
            ),
    );
  }
}

class _CaptainApprovalCard extends StatelessWidget {
  final UserModel captain;
  final bool isArabic;
  final ValueChanged<String> onDecision;

  const _CaptainApprovalCard({
    required this.captain,
    required this.isArabic,
    required this.onDecision,
  });

  String? _url(String? path) {
    if (path == null) return null;
    return '${AppConstants.baseUrl.replaceFirst('/api', '')}$path';
  }

  @override
  Widget build(BuildContext context) {
    final documents = [
      (isArabic ? 'الصورة الشخصية' : 'Profil', captain.avatar),
      (isArabic ? 'بطاقة التعريف' : 'Identité', captain.idCardImage),
      (isArabic ? 'الدراجة' : 'Moto', captain.vehicleImage),
      (
        isArabic ? 'تسجيل الدراجة' : 'Carte grise',
        captain.vehicleRegistrationImage,
      ),
      (isArabic ? 'التصريح' : 'Autorisation', captain.permitImage),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: _url(captain.avatar) != null
                      ? NetworkImage(_url(captain.avatar)!)
                      : null,
                  child: captain.avatar == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        captain.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${captain.phone} • ${captain.email}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final (label, path) = documents[index];
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: _url(path) == null
                            ? const Center(
                                child: Icon(Icons.image_not_supported),
                              )
                            : Image.network(
                                _url(path)!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onDecision('rejected'),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(isArabic ? 'رفض' : 'Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onDecision('approved'),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(isArabic ? 'قبول' : 'Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyApprovals extends StatelessWidget {
  final bool isArabic;

  const _EmptyApprovals({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 70,
            color: AppColors.success,
          ),
          const SizedBox(height: 14),
          Text(
            isArabic ? 'لا توجد طلبات معلقة' : 'Aucune demande en attente',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
