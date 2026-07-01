import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../providers/auth_provider.dart';

class CaptainPendingPage extends ConsumerWidget {
  const CaptainPendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final isRejected = auth.approvalStatus == 'rejected';

    ref.listen(authProvider, (previous, next) {
      if (previous?.approvalStatus != 'approved' &&
          next.approvalStatus == 'approved') {
        context.go(
          next.role == AppConstants.roleCarCaptain
              ? '/car-captain'
              : '/livreur',
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        actions: const [
          LanguageButton(color: AppColors.primary),
          LogoutButton(color: AppColors.textPrimary),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: (isRejected ? AppColors.error : AppColors.warning)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected
                      ? Icons.cancel_outlined
                      : Icons.hourglass_top_rounded,
                  size: 58,
                  color: isRejected ? AppColors.error : AppColors.warning,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                isRejected
                    ? (isAr ? 'تعذر قبول الحساب' : 'Compte non validé')
                    : (isAr ? 'حسابك قيد المراجعة' : 'Compte en vérification'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isRejected
                    ? (isAr
                          ? 'راجع مستنداتك أو تواصل مع الإدارة لإعادة التحقق.'
                          : "Vérifiez vos documents ou contactez l'administration.")
                    : (isAr
                          ? 'استلمنا صورك ومستنداتك. لا يمكنك استقبال الطلبات حتى تعتمد الإدارة حسابك.'
                          : "Vos documents ont été reçus. Vous pourrez travailler après validation par l'administration."),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 30),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authProvider.notifier).refreshProfile(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  isAr ? 'تحديث حالة الحساب' : 'Actualiser le statut',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(240, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
