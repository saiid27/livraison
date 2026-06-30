import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LivreurProfilePage extends ConsumerWidget {
  const LivreurProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/livreur'),
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
                (user?.name ?? 'L')[0].toUpperCase(),
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
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(s.roleLivreur, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(label: s.deliveriesLabel, value: '0'),
                    _Divider(),
                    _Stat(label: s.ratingLabel, value: '5.0'),
                    _Divider(),
                    _Stat(label: s.incomeLabel, value: '0'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ProfileItem(icon: Icons.person_outlined, title: s.personalInfo, onTap: () {}),
            _ProfileItem(icon: Icons.history, title: s.deliveryHistory, onTap: () {}),
            _ProfileItem(icon: Icons.star_outlined, title: s.myRatings, onTap: () {}),
            _ProfileItem(icon: Icons.help_outline, title: s.helpSupport, onTap: () {}),
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
