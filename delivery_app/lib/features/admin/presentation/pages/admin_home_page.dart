import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final items = [
      _AdminItem(
        isAr ? 'طلبات إنشاء الحساب' : 'Demandes de comptes',
        Icons.how_to_reg_outlined,
        AppColors.warning,
        () => context.go('/admin/approvals'),
      ),
      _AdminItem(
        isAr ? 'الصندوق' : 'Caisse',
        Icons.account_balance_wallet_outlined,
        AppColors.success,
        () => context.go('/admin/cashbox'),
      ),
      _AdminItem(
        isAr ? 'طلبات شحن' : 'Demandes de recharge',
        Icons.add_card_outlined,
        Colors.purple,
        () => context.go('/admin/recharge-requests'),
      ),
      _AdminItem(
        isAr ? 'طرق الدفع' : 'Moyens de paiement',
        Icons.credit_score_outlined,
        Colors.indigo,
        () => context.go('/admin/payment-methods'),
      ),
      _AdminItem(
        isAr ? 'طلبات حذف الحساب' : 'Suppressions de comptes',
        Icons.person_remove_outlined,
        AppColors.error,
        () => context.go('/admin/account-deletion-requests'),
      ),
      _AdminItem(
        isAr ? 'سجل الطلبات' : 'Historique des commandes',
        Icons.receipt_long_outlined,
        AppColors.primary,
        () => context.go('/admin/orders'),
      ),
      _AdminItem(
        isAr ? 'قائمة الكباتنة' : 'Liste des capitaines',
        Icons.delivery_dining_outlined,
        Colors.teal,
        () => context.go('/admin/captains'),
      ),
      _AdminItem(
        isAr ? 'قائمة التجار' : 'Liste des commerçants',
        Icons.storefront_outlined,
        AppColors.secondary,
        () => context.go('/admin/merchants'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'حساب الديفلوبر' : 'Compte développeur'),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'لوحة إدارة المنصة' : "Gestion de la plateforme",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isAr
                            ? 'كل أدوات الإدارة في مكان واحد'
                            : 'Tous les outils au même endroit',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.12,
            ),
            itemBuilder: (context, index) => _AdminMenuCard(item: items[index]),
          ),
        ],
      ),
    );
  }
}

class _AdminItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminItem(this.title, this.icon, this.color, this.onTap);
}

class _AdminMenuCard extends StatelessWidget {
  final _AdminItem item;

  const _AdminMenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: item.color.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              Text(
                item.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
