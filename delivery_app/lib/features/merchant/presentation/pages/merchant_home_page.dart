import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/merchant_provider.dart';

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
        title: _MerchantAvatarButton(
          avatarUrl: avatarUrl,
          radius: 17,
          onTap: () => _showProfileMenu(isAr),
        ),
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
                  onTap: () => _showProfileMenu(isAr),
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

  Future<void> _showProfileMenu(bool isAr) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(isAr ? 'تبديل الصورة' : 'Changer la photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _changeAvatar(isAr);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(
                isAr
                    ? 'رقم التواصل ورقم الدفع'
                    : 'Contact et numéro de paiement',
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/merchant/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(isAr ? 'وسائل الدفع' : 'Moyens de paiement'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go('/merchant/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: Text(
                isAr ? 'تغيير كلمة المرور' : 'Changer le mot de passe',
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showChangePasswordDialog(isAr);
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: Text(isAr ? 'طلب المساعدة' : 'Demander de l’aide'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showHelpDialog(isAr);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeAvatar(bool isAr) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    final user = ref.read(authProvider).user;
    final error = await ref
        .read(merchantProvider.notifier)
        .updateProfile(
          contactPhone: user?.merchantContactPhone ?? '',
          paymentPhone: user?.merchantPaymentPhone ?? '',
          avatarPath: image.path,
        );
    await ref.read(authProvider.notifier).refreshProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? null : AppColors.error,
        content: Text(error ?? (isAr ? 'تم تبديل الصورة' : 'Photo changée')),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(bool isAr) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'تغيير كلمة المرور' : 'Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: isAr ? 'كلمة المرور الحالية' : 'Mot de passe actuel',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: isAr
                    ? 'كلمة المرور الجديدة'
                    : 'Nouveau mot de passe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isAr ? 'إلغاء' : 'Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isAr ? 'حفظ' : 'Enregistrer'),
          ),
        ],
      ),
    );
    final currentPassword = currentCtrl.text;
    final newPassword = newCtrl.text;
    currentCtrl.dispose();
    newCtrl.dispose();
    if (confirmed != true) return;

    try {
      await ApiClient.instance.put(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم تغيير كلمة المرور' : 'Mot de passe changé'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            isAr
                ? 'تعذر تغيير كلمة المرور'
                : 'Impossible de changer le mot de passe',
          ),
        ),
      );
    }
  }

  Future<void> _showHelpDialog(bool isAr) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'طلب المساعدة' : 'Aide'),
        content: Text(
          isAr
              ? 'نحن دائمًا في خدمتكم.\n\nواتساب: 22233398\nواتساب: 34339292\nواتساب: 41196566'
              : 'Nous sommes toujours à votre service.\n\nWhatsApp : 22233398\nWhatsApp : 34339292\nWhatsApp : 41196566',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'حسنًا' : 'OK'),
          ),
        ],
      ),
    );
  }
}

class _MerchantAvatarButton extends StatelessWidget {
  const _MerchantAvatarButton({
    required this.avatarUrl,
    required this.radius,
    required this.onTap,
  });

  final String? avatarUrl;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: onTap,
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
