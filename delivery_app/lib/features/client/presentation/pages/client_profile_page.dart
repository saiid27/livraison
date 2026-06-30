import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ClientProfilePage extends ConsumerWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client'),
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
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(s.roleClient, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
            _ProfileItem(icon: Icons.person_outlined, title: s.personalInfo, onTap: () {}),
            _ProfileItem(icon: Icons.receipt_long, title: s.orderHistory, onTap: () => context.go('/client/orders')),
            _ProfileItem(icon: Icons.notifications_outlined, title: s.notifications, onTap: () {}),
            _ProfileItem(icon: Icons.help_outline, title: s.helpSupport, onTap: () {}),
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
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authProvider.notifier).logout();
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _ProfileItem({required this.icon, required this.title, required this.onTap, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
      ),
    );
  }
}
