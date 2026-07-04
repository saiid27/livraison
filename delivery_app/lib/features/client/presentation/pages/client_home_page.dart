import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ClientHomePage extends ConsumerWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'الرئيسية' : 'Accueil'),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            isAr
                ? 'مرحبًا، ${user?.name ?? 'زبوننا'}'
                : 'Bonjour, ${user?.name ?? 'client'}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'ماذا تريد أن تطلب اليوم؟'
                : "Que souhaitez-vous aujourd'hui ?",
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          _ServiceCard(
            title: isAr ? 'طلب خدمة توصيل' : 'Service de livraison',
            subtitle: isAr
                ? 'أرسل طردًا من مكان إلى آخر'
                : "Envoyer un colis d'un point à un autre",
            icon: Icons.two_wheeler_outlined,
            color: AppColors.primary,
            onTap: () => context.go('/client/new-order'),
          ),
          const SizedBox(height: 14),
          _ServiceCard(
            title: isAr ? 'تسوق وشراء عبر الإنترنت' : 'Achats en ligne',
            subtitle: isAr
                ? 'تصفح المنتجات واطلبها من التجار'
                : 'Parcourir et commander les produits des commerçants',
            icon: Icons.shopping_bag_outlined,
            color: AppColors.secondary,
            onTap: () => context.go('/client/marketplace'),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
            child: _CallCenterButton(isAr: isAr),
          ),
        ],
      ),
    );
  }
}

class _CallCenterButton extends StatelessWidget {
  final bool isAr;
  static final Uri _whatsAppUri = Uri.parse(
    'whatsapp://send?phone=${AppConstants.supportWhatsAppPhone}',
  );
  static final Uri _whatsAppWebUri = Uri.parse(
    'https://wa.me/${AppConstants.supportWhatsAppPhone}',
  );

  const _CallCenterButton({required this.isAr});

  Future<void> _openWhatsApp() async {
    final opened = await launchUrl(
      _whatsAppUri,
      mode: LaunchMode.externalApplication,
    );
    if (opened) return;

    await launchUrl(_whatsAppWebUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _openWhatsApp,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox.square(
          dimension: 126,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(height: 10),
                Text(
                  isAr ? 'اتصال بالمركز' : 'Contacter le centre',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
