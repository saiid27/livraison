import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/livreur_provider.dart';

class LivreurProfilePage extends ConsumerStatefulWidget {
  final String baseRoute;
  final String roleLabelAr;
  final String roleLabelFr;

  const LivreurProfilePage({
    super.key,
    this.baseRoute = '/livreur',
    this.roleLabelAr = 'كابتن توصيل',
    this.roleLabelFr = 'Capitaine de livraison',
  });

  @override
  ConsumerState<LivreurProfilePage> createState() => _LivreurProfilePageState();
}

class _LivreurProfilePageState extends ConsumerState<LivreurProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authProvider.notifier).refreshProfile();
      ref.read(livreurProvider.notifier).loadData();
    });
  }

  String? _imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConstants.baseUrl.replaceAll('/api', '')}$path';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final orders = ref.watch(livreurProvider).myOrders;
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final delivered = orders.where((order) => order.status == 'livre').toList();
    final income = delivered.fold<double>(
      0,
      (total, order) => total + (order.price ?? 0),
    );
    final avatarUrl = _imageUrl(user?.avatar);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(widget.baseRoute),
        ),
        actions: [const LanguageButton(), const LogoutButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: avatarUrl == null
                  ? null
                  : NetworkImage(avatarUrl),
              child: avatarUrl != null
                  ? null
                  : Text(
                      (user?.name.isNotEmpty == true ? user!.name : 'L')[0]
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.phone ?? '',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isAr ? widget.roleLabelAr : widget.roleLabelFr,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(
                      label: s.deliveriesLabel,
                      value: delivered.length.toString(),
                    ),
                    _Divider(),
                    _Stat(
                      label: s.incomeLabel,
                      value: income.toStringAsFixed(0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ProfileItem(
              icon: Icons.person_outlined,
              title: s.personalInfo,
              onTap: () => _showPersonalInfo(context, isAr),
            ),
            _ProfileItem(
              icon: Icons.history,
              title: s.deliveryHistory,
              onTap: () => context.go('${widget.baseRoute}/history'),
            ),
            _ProfileItem(
              icon: Icons.help_outline,
              title: s.helpSupport,
              onTap: () => _showSupport(context, isAr),
            ),
            const SizedBox(height: 8),
            _ProfileItem(
              icon: Icons.logout,
              title: s.logout,
              color: AppColors.error,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(s.logoutTitle),
                    content: Text(s.logoutConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(s.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authProvider.notifier).logout();
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: Text(s.disconnect),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPersonalInfo(BuildContext context, bool isAr) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final images = [
      (
        title: isAr ? 'الصورة الشخصية' : 'Photo personnelle',
        url: _imageUrl(user.avatar),
      ),
      (
        title: isAr ? 'بطاقة التعريف' : 'Carte d’identité',
        url: _imageUrl(user.idCardImage),
      ),
      (
        title: isAr ? 'صورة الموتو' : 'Photo moto',
        url: _imageUrl(user.vehicleImage),
      ),
      (
        title: isAr ? 'صورة ترخيص المركبة' : 'Immatriculation',
        url: _imageUrl(user.vehicleRegistrationImage),
      ),
      (
        title: isAr ? 'صورة التصريح' : 'Permis',
        url: _imageUrl(user.permitImage),
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              isAr ? 'المعلومات الشخصية' : 'Informations personnelles',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _InfoTile(label: isAr ? 'الاسم' : 'Nom', value: user.name),
            _InfoTile(
              label: isAr ? 'رقم الهاتف' : 'Téléphone',
              value: user.phone,
            ),
            _InfoTile(label: isAr ? 'البريد' : 'Email', value: user.email),
            const SizedBox(height: 10),
            for (final image in images)
              _DocumentImageTile(
                title: image.title,
                imageUrl: image.url,
                isAr: isAr,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSupport(BuildContext context, bool isAr) async {
    const phones = ['22233398', '34339292', '41196566'];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAr ? 'المساعدة والدعم' : 'Aide et support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAr
                  ? 'يمكنك التواصل معنا عبر واتساب:'
                  : 'Vous pouvez nous contacter sur WhatsApp :',
            ),
            const SizedBox(height: 12),
            for (final phone in phones)
              ListTile(
                dense: true,
                leading: const Icon(Icons.phone_outlined),
                title: Text(phone),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isAr ? 'إغلاق' : 'Fermer'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.border);
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      subtitle: Text(
        value.isEmpty ? '-' : value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DocumentImageTile extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final bool isAr;

  const _DocumentImageTile({
    required this.title,
    required this.imageUrl,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: hasImage ? () => _openImage(context) : null,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 54,
            height: 54,
            color: AppColors.primary.withValues(alpha: 0.08),
            child: hasImage
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.error,
                    ),
                  )
                : const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          hasImage
              ? (isAr ? 'اضغط لعرض الصورة' : 'Toucher pour afficher')
              : (isAr ? 'لا توجد صورة' : 'Aucune image'),
        ),
        trailing: hasImage ? const Icon(Icons.chevron_right) : null,
      ),
    );
  }

  void _openImage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'الصورة غير متوفرة على السيرفر',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: color.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
