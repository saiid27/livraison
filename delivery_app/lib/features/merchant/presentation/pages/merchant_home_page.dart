import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MerchantHomePage extends ConsumerWidget {
  const MerchantHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final user = ref.watch(authProvider).user;
    final items = [
      _MerchantItem(
        isAr ? 'إضافة منتجات' : 'Ajouter des produits',
        Icons.add_box_outlined,
        AppColors.primary,
      ),
      _MerchantItem(
        isAr ? 'المنتجات المتوفرة' : 'Produits disponibles',
        Icons.inventory_2_outlined,
        AppColors.success,
      ),
      _MerchantItem(
        isAr ? 'سجل البيع' : 'Historique des ventes',
        Icons.point_of_sale_outlined,
        AppColors.secondary,
      ),
      _MerchantItem(
        isAr ? 'الطلبات' : 'Commandes',
        Icons.shopping_bag_outlined,
        Colors.purple,
      ),
      _MerchantItem(
        isAr ? 'سجل الطلبات' : 'Historique des commandes',
        Icons.history_rounded,
        Colors.teal,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'مساحة التاجر' : 'Espace commerçant'),
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
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.storefront, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? (isAr ? 'التاجر' : 'Commerçant'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isAr
                            ? 'إدارة المتجر والطلبات'
                            : 'Gestion de la boutique',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isAr ? 'إدارة المتجر' : 'Gestion du commerce',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => _MerchantMenuCard(
              item: item,
              onTap: () => _comingSoon(context, isAr),
            ),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, bool isAr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'سيتم تفعيل هذه الخاصية لاحقًا'
              : 'Fonction disponible prochainement',
        ),
      ),
    );
  }
}

class _MerchantItem {
  final String title;
  final IconData icon;
  final Color color;

  const _MerchantItem(this.title, this.icon, this.color);
}

class _MerchantMenuCard extends StatelessWidget {
  final _MerchantItem item;
  final VoidCallback onTap;

  const _MerchantMenuCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(item.icon, color: item.color),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
