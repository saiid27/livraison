import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class LogoutButton extends ConsumerWidget {
  final Color color;
  const LogoutButton({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return IconButton(
      tooltip: s.logout,
      icon: Icon(Icons.logout, color: color),
      onPressed: () => _confirm(context, ref, s),
    );
  }

  void _confirm(BuildContext context, WidgetRef ref, s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppColors.error),
            const SizedBox(width: 8),
            Text(s.logoutTitle),
          ],
        ),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(s.disconnect),
          ),
        ],
      ),
    );
  }
}
