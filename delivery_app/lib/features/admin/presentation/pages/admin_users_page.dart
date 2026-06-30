import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/providers/language_provider.dart';
import '../providers/admin_provider.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(adminProvider.notifier).loadUsers());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final s = ref.watch(stringsProvider);
    final clients = state.users.where((u) => u.role == 'client').toList();
    final livreurs = state.users.where((u) => u.role == 'livreur').toList();
    final merchants = state.users.where((u) => u.role == 'merchant').toList();
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.usersLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [const LanguageButton(), const LogoutButton()],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '${s.clientsLabel} (${clients.length})'),
            Tab(
              text: '${isAr ? 'الكباتنة' : 'Capitaines'} (${livreurs.length})',
            ),
            Tab(
              text: '${isAr ? 'التجار' : 'Commerçants'} (${merchants.length})',
            ),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _UserList(
                  users: clients,
                  roleLabel: s.roleClient,
                  color: AppColors.primary,
                  emptyLabel: s.noUser,
                ),
                _UserList(
                  users: livreurs,
                  roleLabel: isAr ? 'كابتن' : 'Capitaine',
                  color: AppColors.success,
                  emptyLabel: s.noUser,
                ),
                _UserList(
                  users: merchants,
                  roleLabel: isAr ? 'تاجر' : 'Commerçant',
                  color: AppColors.secondary,
                  emptyLabel: s.noUser,
                ),
              ],
            ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<dynamic> users;
  final String roleLabel;
  final Color color;
  final String emptyLabel;

  const _UserList({
    required this.users,
    required this.roleLabel,
    required this.color,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              emptyLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final user = users[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Text(
                (user.name)[0].toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Text(
                  user.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
