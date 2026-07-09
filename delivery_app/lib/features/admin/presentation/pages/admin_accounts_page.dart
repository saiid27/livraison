import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../auth/data/models/user_model.dart';

class AdminAccountsPage extends ConsumerStatefulWidget {
  const AdminAccountsPage({super.key});

  @override
  ConsumerState<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends ConsumerState<AdminAccountsPage> {
  late Future<List<UserModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAdmins();
  }

  Future<List<UserModel>> _loadAdmins() async {
    final response = await ApiClient.instance.get('/admin/admin-accounts');
    return (response.data['users'] as List)
        .map((user) => UserModel.fromJson(user))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadAdmins());
    await _future;
  }

  Future<void> _showCreateSheet(bool isAr) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool asDeveloper = false;
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isAr ? 'إضافة حساب أدمن' : 'Ajouter un admin',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الاسم' : 'Nom',
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? (isAr ? 'مطلوب' : 'Obligatoire')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: isAr ? 'رقم الهاتف' : 'Téléphone',
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? (isAr ? 'مطلوب' : 'Obligatoire')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: isAr
                        ? 'البريد الإلكتروني اختياري'
                        : 'Email facultatif',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isAr ? 'كلمة المرور' : 'Mot de passe',
                  ),
                  validator: (value) {
                    final password = value?.trim() ?? '';
                    if (password.isEmpty) {
                      return isAr ? 'مطلوب' : 'Obligatoire';
                    }
                    if (password.length < 6) {
                      return isAr ? '6 أحرف على الأقل' : '6 caractères minimum';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: asDeveloper,
                  onChanged: (value) => setModal(() => asDeveloper = value),
                  title: Text(
                    isAr ? 'جعله حساب ديفلوبر' : 'Compte développeur',
                  ),
                  subtitle: Text(
                    isAr
                        ? 'يمكنه إضافة أدمن أو ديفلوبر آخر'
                        : 'Peut ajouter un autre admin ou développeur',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModal(() => isSubmitting = true);
                          final error = await _createAdmin(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            password: passwordCtrl.text.trim(),
                            isDeveloper: asDeveloper,
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error ??
                                    (isAr
                                        ? 'تم إنشاء حساب الأدمن'
                                        : 'Compte admin créé'),
                              ),
                              backgroundColor: error == null
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          );
                          if (error == null) await _refresh();
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isAr ? 'حفظ' : 'Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _createAdmin({
    required String name,
    required String phone,
    required String email,
    required String password,
    required bool isDeveloper,
  }) async {
    try {
      await ApiClient.instance.post(
        '/admin/admin-accounts',
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'is_developer': isDeveloper,
        },
      );
      return null;
    } on DioException catch (error) {
      if (error.response?.data is Map) {
        return error.response?.data['message']?.toString();
      }
      return 'Erreur';
    }
  }

  Future<String?> _updateDeveloperAccess(UserModel admin, bool value) async {
    try {
      await ApiClient.instance.put(
        '/admin/admin-accounts/${admin.id}',
        data: {'is_developer': value},
      );
      return null;
    } on DioException catch (error) {
      if (error.response?.data is Map) {
        return error.response?.data['message']?.toString();
      }
      return 'Erreur';
    }
  }

  Future<String?> _deleteAdmin(UserModel admin) async {
    try {
      await ApiClient.instance.delete('/admin/admin-accounts/${admin.id}');
      return null;
    } on DioException catch (error) {
      if (error.response?.data is Map) {
        return error.response?.data['message']?.toString();
      }
      return 'Erreur';
    }
  }

  Future<void> _toggleDeveloper(UserModel admin, bool isAr) async {
    final makeDeveloper = !admin.isDeveloper;
    final error = await _updateDeveloperAccess(admin, makeDeveloper);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (makeDeveloper
                  ? (isAr ? 'تم تحويله إلى ديفلوبر' : 'Accès développeur donné')
                  : (isAr ? 'تم تحويله إلى أدمن' : 'Converti en admin')),
        ),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
    if (error == null) await _refresh();
  }

  Future<void> _confirmDelete(UserModel admin, bool isAr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? 'حذف الحساب' : 'Supprimer le compte'),
        content: Text(
          isAr
              ? 'هل تريد حذف حساب ${admin.name}؟'
              : 'Supprimer le compte ${admin.name} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isAr ? 'إلغاء' : 'Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isAr ? 'حذف' : 'Supprimer',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final error = await _deleteAdmin(admin);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? (isAr ? 'تم حذف الحساب' : 'Compte supprimé')),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
    if (error == null) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'حسابات الأدمن' : 'Comptes admin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
        ),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(isAr),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(isAr ? 'إضافة أدمن' : 'Ajouter'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                isAr
                    ? 'هذه الصفحة خاصة بحساب الديفلوبر'
                    : 'Page réservée au développeur',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          final admins = snapshot.data ?? const [];
          if (admins.isEmpty) {
            return Center(
              child: Text(
                isAr ? 'لا توجد حسابات أدمن' : 'Aucun compte admin',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: admins.length,
              itemBuilder: (context, index) {
                final admin = admins[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: admin.isDeveloper
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surface,
                      child: Icon(
                        admin.isDeveloper
                            ? Icons.admin_panel_settings
                            : Icons.manage_accounts_outlined,
                        color: admin.isDeveloper
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    title: Text(
                      admin.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${admin.phone}\n${admin.email}\n${admin.isDeveloper ? (isAr ? 'ديفلوبر' : 'Développeur') : (isAr ? 'أدمن' : 'Admin')}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'toggle') {
                          _toggleDeveloper(admin, isAr);
                        } else if (value == 'delete') {
                          _confirmDelete(admin, isAr);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                admin.isDeveloper
                                    ? Icons.manage_accounts_outlined
                                    : Icons.admin_panel_settings_outlined,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                admin.isDeveloper
                                    ? (isAr
                                          ? 'تحويل إلى أدمن'
                                          : 'Convertir en admin')
                                    : (isAr
                                          ? 'تحويل إلى ديفلوبر'
                                          : 'Convertir en développeur'),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'حذف' : 'Supprimer',
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
