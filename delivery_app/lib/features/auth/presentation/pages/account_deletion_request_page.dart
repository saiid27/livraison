import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AccountDeletionRequestPage extends ConsumerStatefulWidget {
  const AccountDeletionRequestPage({super.key});

  @override
  ConsumerState<AccountDeletionRequestPage> createState() =>
      _AccountDeletionRequestPageState();
}

class _AccountDeletionRequestPageState
    extends ConsumerState<AccountDeletionRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _isChecking = false;
  String? _verifiedUserName;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _phoneCtrl.text = user.phone;
      _verifiedUserName = user.name;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPhone(bool isAr) async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'رقم الهاتف مطلوب' : 'Téléphone requis')),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _verifiedUserName = null;
    });
    try {
      final response = await ApiClient.instance.post(
        '/auth/account-deletion-requests/check-phone',
        data: {'phone': phone},
      );
      if (!mounted) return;
      setState(() {
        _verifiedUserName = response.data['user']?['name'] ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.data['message'] ??
                (isAr ? 'تم التحقق من وجود الحساب' : 'Compte vérifié'),
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            error.response?.data['message'] ??
                (isAr ? 'لم يتم العثور على الحساب' : 'Compte introuvable'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _submit(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;
    if (_verifiedUserName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تحقق من رقم الهاتف أولًا' : 'Vérifiez le numéro d’abord',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await ApiClient.instance.post(
        '/auth/account-deletion-requests',
        data: {
          'phone': _phoneCtrl.text.trim(),
          'reason': _reasonCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.data['message'] ??
                (isAr
                    ? 'تم إرسال طلب حذف الحساب'
                    : 'Demande envoyée avec succès'),
          ),
        ),
      );
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    } on DioException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            error.response?.data['message'] ??
                (isAr ? 'تعذر إرسال الطلب' : 'Impossible d’envoyer la demande'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final authState = ref.watch(authProvider);
    final fallbackRoute = switch (authState.role) {
      'client' => '/client',
      'livreur' => '/livreur',
      'car_captain' => '/car-captain',
      'merchant' => '/merchant',
      'admin' => '/admin',
      _ => '/login',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'طلب حذف حسابي' : 'Supprimer mon compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(fallbackRoute),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.primary,
                  size: 54,
                ),
                const SizedBox(height: 18),
                Text(
                  isAr ? 'أرسل طلب حذف الحساب' : 'Envoyer une demande',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isAr
                      ? 'أدخل رقم هاتف الحساب، ثم اكتب سبب طلب الحذف. سيتم إرسال الطلب إلى الإدارة للمراجعة.'
                      : 'Entrez le numéro du compte, puis indiquez la raison. La demande sera envoyée à l’administration.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() => _verifiedUserName = null),
                  decoration: InputDecoration(
                    labelText: isAr ? 'رقم الهاتف' : 'Téléphone',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isAr ? 'رقم الهاتف مطلوب' : 'Téléphone requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isChecking ? null : () => _checkPhone(isAr),
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user_outlined),
                  label: Text(isAr ? 'تحقق من الرقم' : 'Vérifier le numéro'),
                ),
                if (_verifiedUserName != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAr
                          ? 'تم العثور على الحساب: $_verifiedUserName'
                          : 'Compte trouvé : $_verifiedUserName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonCtrl,
                    minLines: 4,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: isAr ? 'سبب طلب حذف الحساب' : 'Raison',
                      alignLabelWithHint: true,
                      prefixIcon: const Icon(Icons.edit_note_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isAr ? 'اكتب سبب الطلب' : 'Raison requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _submit(isAr),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(isAr ? 'إرسال الطلب' : 'Envoyer'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
