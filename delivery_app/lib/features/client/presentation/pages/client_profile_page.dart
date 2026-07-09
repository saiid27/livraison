import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ClientProfilePage extends ConsumerWidget {
  const ClientProfilePage({super.key});

  static final Uri _whatsAppUri = Uri.parse(
    'whatsapp://send?phone=${AppConstants.supportWhatsAppPhone}',
  );
  static final Uri _whatsAppWebUri = Uri.parse(
    'https://wa.me/${AppConstants.supportWhatsAppPhone}',
  );

  Future<void> _openWhatsApp() async {
    final opened = await launchUrl(
      _whatsAppUri,
      mode: LaunchMode.externalApplication,
    );
    if (opened) return;

    await launchUrl(_whatsAppWebUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showPersonalInfo(
    BuildContext context,
    WidgetRef ref,
    bool isAr,
  ) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.6,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/client'),
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
              child: Text(
                (user?.name ?? 'U')[0].toUpperCase(),
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
              user?.email ?? '',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                s.roleClient,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _ProfileItem(
              icon: Icons.person_outlined,
              title: s.personalInfo,
              onTap: () => _showPersonalInfo(context, ref, isAr),
            ),
            _ProfileItem(
              icon: Icons.receipt_long,
              title: s.orderHistory,
              onTap: () => context.go('/client/orders'),
            ),
            _ProfileItem(
              icon: Icons.help_outline,
              title: s.helpSupport,
              onTap: _openWhatsApp,
            ),
            const SizedBox(height: 16),
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
