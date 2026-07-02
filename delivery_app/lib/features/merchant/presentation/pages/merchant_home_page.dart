import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MerchantHomePage extends ConsumerStatefulWidget {
  const MerchantHomePage({super.key});

  @override
  ConsumerState<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends ConsumerState<MerchantHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).refreshProfile());
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final user = ref.watch(authProvider).user;
    final avatarUrl = _imageUrl(user?.avatar);
    final items = [
      _MerchantItem(
        isAr ? 'إضافة منتجات' : 'Ajouter des produits',
        Icons.add_box_outlined,
        AppColors.primary,
        () => context.go('/merchant/products/add'),
      ),
      _MerchantItem(
        isAr ? 'المنتجات المتوفرة' : 'Produits disponibles',
        Icons.inventory_2_outlined,
        AppColors.success,
        () => context.go('/merchant/products'),
      ),
      _MerchantItem(
        isAr ? 'سجل البيع' : 'Historique des ventes',
        Icons.point_of_sale_outlined,
        AppColors.secondary,
        () => context.go('/merchant/sales'),
      ),
      _MerchantItem(
        isAr ? 'الطلبات' : 'Commandes',
        Icons.shopping_bag_outlined,
        Colors.purple,
        () => context.go('/merchant/orders'),
      ),
      _MerchantItem(
        isAr ? 'سجل الطلبات' : 'Historique des commandes',
        Icons.history_rounded,
        Colors.teal,
        () => context.go('/merchant/order-history'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _MerchantAvatarButton(avatarUrl: avatarUrl, radius: 17),
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
                InkWell(
                  onTap: () => context.go('/merchant/profile'),
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _MerchantAvatar(avatarUrl: avatarUrl, radius: 28),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
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
          ...items.map((item) => _MerchantMenuCard(item: item)),
        ],
      ),
    );
  }

  String? _imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConstants.baseUrl.replaceAll('/api', '')}$path';
  }
}

class _MerchantAvatarButton extends StatelessWidget {
  const _MerchantAvatarButton({required this.avatarUrl, required this.radius});

  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: () => context.go('/merchant/profile'),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: _MerchantAvatar(avatarUrl: avatarUrl, radius: radius),
        ),
      ),
    );
  }
}

class _MerchantAvatar extends StatelessWidget {
  const _MerchantAvatar({required this.avatarUrl, required this.radius});

  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
      child: avatarUrl == null
          ? Icon(Icons.storefront, color: Colors.white, size: radius)
          : null,
    );
  }
}

class _MerchantItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MerchantItem(this.title, this.icon, this.color, this.onTap);
}

class _MerchantMenuCard extends StatelessWidget {
  final _MerchantItem item;

  const _MerchantMenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      child: ListTile(
        onTap: item.onTap,
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
