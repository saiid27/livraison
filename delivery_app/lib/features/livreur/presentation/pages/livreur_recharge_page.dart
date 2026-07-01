import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../providers/wallet_provider.dart';
import '../../data/models/payment_method_model.dart';

class LivreurRechargePage extends ConsumerStatefulWidget {
  final String baseRoute;

  const LivreurRechargePage({super.key, this.baseRoute = '/livreur'});

  @override
  ConsumerState<LivreurRechargePage> createState() =>
      _LivreurRechargePageState();
}

class _LivreurRechargePageState extends ConsumerState<LivreurRechargePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  PaymentMethodModel? _selectedMethod;
  String? _screenshotPath;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(walletProvider.notifier).loadPaymentMethods(),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _screenshotPath = picked.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMethod == null) {
      _showSnack(
        ref.read(localeProvider).languageCode == 'ar'
            ? 'الرجاء اختيار طريقة الدفع'
            : 'Veuillez sélectionner un moyen de paiement',
        isError: true,
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final error = await ref
        .read(walletProvider.notifier)
        .submitRequest(
          amount: amount,
          phoneFrom: _phoneCtrl.text.trim(),
          paymentMethodId: _selectedMethod!.id,
          screenshotPath: _screenshotPath,
        );

    if (!mounted) return;
    if (error == null) {
      _showSnack(
        ref.read(localeProvider).languageCode == 'ar'
            ? 'تم إرسال طلب الشحن بنجاح'
            : 'Demande de recharge envoyée avec succès',
      );
      context.go('${widget.baseRoute}/wallet');
    } else {
      _showSnack(error, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  String get _imageBase => AppConstants.baseUrl.replaceAll('/api', '');

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final walletState = ref.watch(walletProvider);
    final methods = walletState.paymentMethods;
    final isSubmitting = walletState.isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'شحن الرصيد' : 'Recharger le solde'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('${widget.baseRoute}/wallet'),
        ),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Payment methods ────────────────────────────────────
              Text(
                isAr ? 'طريقة الدفع' : 'Moyen de paiement',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              if (methods.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: methods.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final m = methods[i];
                      final selected = _selectedMethod?.id == m.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMethod = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 110,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MethodLogo(
                                logoUrl: m.logoUrl != null
                                    ? '$_imageBase${m.logoUrl}'
                                    : null,
                                size: 44,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                m.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Show payment number after selection
              if (_selectedMethod != null) ...[
                const SizedBox(height: 12),
                _InfoBox(
                  icon: Icons.phone_in_talk_rounded,
                  label: isAr ? 'رقم الدفع' : 'Numéro de paiement',
                  value: _selectedMethod!.phoneNumber,
                  onCopy: () {
                    Clipboard.setData(
                      ClipboardData(text: _selectedMethod!.phoneNumber),
                    );
                    _showSnack(isAr ? 'تم النسخ' : 'Numéro copié');
                  },
                ),
              ],

              const SizedBox(height: 22),

              // ── Amount ────────────────────────────────────────────
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: isAr ? 'المبلغ (أوقية)' : 'Montant (MRU)',
                  prefixIcon: const Icon(Icons.monetization_on_rounded),
                ),
                validator: (v) {
                  final val = double.tryParse(v?.trim() ?? '');
                  if (val == null || val <= 0) {
                    return isAr
                        ? 'أدخل مبلغاً صحيحاً'
                        : 'Entrez un montant valide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Phone from ────────────────────────────────────────
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isAr
                      ? 'رقم الهاتف المرسِل'
                      : 'N° de téléphone émetteur',
                  prefixIcon: const Icon(Icons.smartphone_rounded),
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) {
                    return isAr
                        ? 'أدخل رقم الهاتف'
                        : 'Entrez le numéro de téléphone';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // ── Screenshot ────────────────────────────────────────
              Text(
                isAr
                    ? 'لقطة شاشة للتحويل (اختياري)'
                    : 'Capture d\'écran du transfert (optionnel)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickScreenshot,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _screenshotPath != null
                          ? AppColors.success
                          : AppColors.border,
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: _screenshotPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            File(_screenshotPath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'انقر لإضافة صورة'
                                  : 'Appuyez pour ajouter une image',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              if (_screenshotPath != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _screenshotPath = null),
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(isAr ? 'إزالة الصورة' : 'Supprimer la photo'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],

              const SizedBox(height: 32),

              // ── Submit button ─────────────────────────────────────
              ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isAr ? 'إرسال طلب الشحن' : 'Envoyer la demande',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment method logo widget ────────────────────────────────────────────────

class _MethodLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const _MethodLogo({this.logoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.payment, size: size * 0.5, color: AppColors.primary),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.payment,
            size: size * 0.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Info box with copy ────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: AppColors.primary,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
