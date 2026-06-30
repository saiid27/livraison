import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../providers/admin_recharge_provider.dart';
import '../../../livreur/data/models/payment_method_model.dart';

class AdminPaymentMethodsPage extends ConsumerStatefulWidget {
  const AdminPaymentMethodsPage({super.key});

  @override
  ConsumerState<AdminPaymentMethodsPage> createState() =>
      _AdminPaymentMethodsPageState();
}

class _AdminPaymentMethodsPageState
    extends ConsumerState<AdminPaymentMethodsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminRechargeProvider.notifier).loadPaymentMethods());
  }

  String get _imageBase => AppConstants.baseUrl.replaceAll('/api', '');

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(adminRechargeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'طرق الدفع' : 'Moyens de paiement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMethodDialog(context, ref, isAr),
        icon: const Icon(Icons.add_rounded),
        label: Text(isAr ? 'إضافة' : 'Ajouter'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.paymentMethods.isEmpty
              ? Center(
                  child: Text(
                    isAr ? 'لا توجد طرق دفع بعد' : 'Aucun moyen de paiement',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(adminRechargeProvider.notifier)
                      .loadPaymentMethods(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: state.paymentMethods.length,
                    itemBuilder: (_, i) => _MethodCard(
                      method: state.paymentMethods[i],
                      isAr: isAr,
                      imageBase: _imageBase,
                    ),
                  ),
                ),
    );
  }

  Future<void> _showMethodDialog(
    BuildContext context,
    WidgetRef ref,
    bool isAr, {
    PaymentMethodModel? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl =
        TextEditingController(text: existing?.phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();
    String? logoPath;
    bool isActive = existing?.isActive ?? true;

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
                  existing == null
                      ? (isAr ? 'إضافة طريقة دفع' : 'Ajouter un moyen')
                      : (isAr ? 'تعديل طريقة الدفع' : 'Modifier le moyen'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),

                // Logo picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setModal(() => logoPath = picked.path);
                    }
                  },
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _LogoPreview(
                        localPath: logoPath,
                        networkUrl: existing?.logoUrl != null
                            ? '${AppConstants.baseUrl.replaceAll('/api', '')}${existing!.logoUrl}'
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    isAr ? 'انقر لتغيير الشعار' : 'Appuyez pour changer le logo',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الاسم' : 'Nom',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? (isAr ? 'مطلوب' : 'Obligatoire')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: isAr ? 'رقم الهاتف' : 'Numéro de téléphone',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? (isAr ? 'مطلوب' : 'Obligatoire')
                      : null,
                ),

                if (existing != null) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setModal(() => isActive = v),
                    title: Text(isAr ? 'نشط' : 'Actif'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);

                    String? err;
                    if (existing == null) {
                      err = await ref
                          .read(adminRechargeProvider.notifier)
                          .createPaymentMethod(
                            name: nameCtrl.text.trim(),
                            phoneNumber: phoneCtrl.text.trim(),
                            logoPath: logoPath,
                          );
                    } else {
                      err = await ref
                          .read(adminRechargeProvider.notifier)
                          .updatePaymentMethod(
                            methodId: existing.id,
                            name: nameCtrl.text.trim(),
                            phoneNumber: phoneCtrl.text.trim(),
                            isActive: isActive,
                            logoPath: logoPath,
                          );
                    }

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        err ??
                            (isAr
                                ? 'تم الحفظ بنجاح'
                                : 'Enregistré avec succès'),
                      ),
                      backgroundColor:
                          err != null ? AppColors.error : AppColors.success,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(isAr ? 'حفظ' : 'Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Logo preview inside the form ──────────────────────────────────────────────

class _LogoPreview extends StatelessWidget {
  final String? localPath;
  final String? networkUrl;

  const _LogoPreview({this.localPath, this.networkUrl});

  @override
  Widget build(BuildContext context) {
    if (localPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          File(localPath!),
          fit: BoxFit.contain,
          width: 90,
          height: 90,
        ),
      );
    }
    if (networkUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          networkUrl!,
          fit: BoxFit.contain,
          width: 90,
          height: 90,
          errorBuilder: (_, __, ___) => const Icon(Icons.payment, size: 36),
        ),
      );
    }
    return const Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textSecondary);
  }
}

// ── Method card ───────────────────────────────────────────────────────────────

class _MethodCard extends ConsumerWidget {
  final PaymentMethodModel method;
  final bool isAr;
  final String imageBase;

  const _MethodCard({
    required this.method,
    required this.isAr,
    required this.imageBase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: method.logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    '$imageBase${method.logoUrl}',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.payment, size: 30),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payment, color: AppColors.primary),
                ),
        ),
        title: Text(
          method.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(method.phoneNumber),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: method.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                method.isActive
                    ? (isAr ? 'نشط' : 'Actif')
                    : (isAr ? 'معطل' : 'Inactif'),
                style: TextStyle(
                  color: method.isActive ? AppColors.success : AppColors.error,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  await (context
                          .findAncestorStateOfType<
                              _AdminPaymentMethodsPageState>())
                      ?._showMethodDialog(
                    context,
                    ref,
                    isAr,
                    existing: method,
                  );
                } else if (v == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(isAr ? 'حذف؟' : 'Supprimer ?'),
                      content: Text(
                        isAr
                            ? 'هل تريد حذف هذا الموقف؟'
                            : 'Voulez-vous supprimer ce moyen ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(isAr ? 'إلغاء' : 'Annuler'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(isAr ? 'حذف' : 'Supprimer'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  final err = await ref
                      .read(adminRechargeProvider.notifier)
                      .deletePaymentMethod(method.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        err ?? (isAr ? 'تم الحذف' : 'Supprimé avec succès')),
                    backgroundColor:
                        err != null ? AppColors.error : AppColors.success,
                  ));
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(isAr ? 'تعديل' : 'Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
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
          ],
        ),
      ),
    );
  }
}
