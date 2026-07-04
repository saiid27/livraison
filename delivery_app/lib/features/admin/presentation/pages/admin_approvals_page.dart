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
                  onDecision: (status) async {
                    final error = await ref
                        .read(adminProvider.notifier)
                        .updateCaptainApproval(state.users[index].id, status);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text(error),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
    );
  }
}

class _CaptainApprovalCard extends StatelessWidget {
  final UserModel captain;
  final bool isArabic;
  final Future<void> Function(String status) onDecision;

  const _CaptainApprovalCard({
    required this.captain,
    required this.isArabic,
    required this.onDecision,
  });

  String? _url(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConstants.baseUrl.replaceFirst('/api', '')}$path';
  }

  void _openImage(BuildContext context, String label, String? path) {
    final imageUrl = _url(path);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'الصورة غير متوفرة' : 'Image indisponible'),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final hasMissingDocuments = documents.any(
      (document) => _url(document.$2) == null,
    );

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
                final imageUrl = _url(path);
                return InkWell(
                  onTap: () => _openImage(context, label, path),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: imageUrl == null
                            ? AppColors.error.withValues(alpha: 0.45)
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: imageUrl == null
                              ? const Center(
                                  child: Icon(Icons.image_not_supported),
                                )
                              : Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            imageUrl == null
                                ? '$label • ${isArabic ? 'ناقصة' : 'manquante'}'
                                : label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: imageUrl == null
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    onPressed: hasMissingDocuments
                        ? null
                        : () => onDecision('approved'),
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
