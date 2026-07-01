import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  static const _otpResendCooldown = Duration(minutes: 8);

  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _codeSent = false;
  bool _otpVerified = false;
  bool _obscurePassword = true;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _accountName;
  Timer? _resendTimer;
  int _remainingSeconds = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSendingOtp || _remainingSeconds > 0) return;
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _message(
        isAr ? 'أدخل رقم الهاتف' : 'Saisissez votre numéro de téléphone',
      );
      return;
    }
    setState(() => _isSendingOtp = true);
    try {
      final accountName = await ref
          .read(authProvider.notifier)
          .requestPasswordReset(phone, lang: isAr ? 'ar' : 'fr');
      if (!mounted || ref.read(authProvider).error != null) return;
      if (accountName == null) return;
      setState(() {
        _codeSent = true;
        _accountName = accountName;
      });
      _startResendCooldown();
      _message(isAr ? 'تم إرسال رمز التحقق' : 'Code de vérification envoyé');
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _remainingSeconds = _otpResendCooldown.inSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  String _formatRemaining() {
    final minutes = (_remainingSeconds ~/ 60).toString();
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _resetPassword() async {
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    if (!_otpVerified) {
      await _verifyCode();
      return;
    }
    if (_passwordController.text.length < 6) {
      _message(
        isAr
            ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
            : 'Le mot de passe doit contenir au moins 6 caractères',
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _message(
        isAr
            ? 'كلمتا المرور غير متطابقتين'
            : 'Les mots de passe ne correspondent pas',
      );
      return;
    }
    final success = await ref
        .read(authProvider.notifier)
        .resetPassword(
          phone: _phoneController.text.trim(),
          code: _codeController.text.trim(),
          password: _passwordController.text,
          lang: isAr ? 'ar' : 'fr',
        );
    if (success && mounted) {
      _message(isAr ? 'تم تغيير كلمة المرور بنجاح' : 'Mot de passe modifié');
      context.go('/login');
    }
  }

  Future<void> _verifyCode() async {
    if (_isVerifyingOtp || _otpVerified) return;
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    if (_codeController.text.trim().length != 6) {
      _message(
        isAr
            ? 'أدخل رمز التحقق المكون من 6 أرقام'
            : 'Saisissez le code à 6 chiffres',
      );
      return;
    }
    setState(() => _isVerifyingOtp = true);
    try {
      final success = await ref
          .read(authProvider.notifier)
          .verifyOtp(
            _phoneController.text.trim(),
            _codeController.text.trim(),
            lang: isAr ? 'ar' : 'fr',
          );
      if (success && mounted) {
        setState(() => _otpVerified = true);
        _message(isAr ? 'تم التحقق من الرمز' : 'Code vérifié');
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.go('/login'),
          icon: Icon(
            isAr ? Icons.arrow_forward : Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [LanguageButton(color: AppColors.primary)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isAr ? 'نسيت كلمة المرور؟' : 'Mot de passe oublié ?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _codeSent
                    ? (_otpVerified
                          ? (isAr
                                ? 'اكتب كلمة المرور الجديدة'
                                : 'Saisissez le nouveau mot de passe')
                          : (isAr
                                ? 'أدخل رمز التحقق وكلمة المرور الجديدة'
                                : 'Saisissez le code de vérification'))
                    : (isAr
                          ? 'أدخل رقم الهاتف وسنرسل لك رمز التحقق'
                          : 'Saisissez votre numéro pour recevoir un code'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _phoneController,
                readOnly: _codeSent,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isAr ? 'رقم الهاتف' : 'Téléphone',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                if (_accountName != null && _accountName!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'الحساب: $_accountName'
                                : 'Compte : $_accountName',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _codeController,
                  readOnly: _otpVerified,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: isAr ? 'رمز التحقق' : 'Code de vérification',
                    prefixIcon: const Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                ),
                if (_otpVerified) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'كلمة المرور الجديدة'
                          : 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'تأكيد كلمة المرور'
                          : 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ],
              if (auth.error != null) ...[
                const SizedBox(height: 14),
                Text(
                  auth.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : (_codeSent ? _resetPassword : _sendCode),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _codeSent
                            ? (_otpVerified
                                  ? (isAr
                                        ? 'تغيير كلمة المرور'
                                        : 'Modifier le mot de passe')
                                  : (isAr ? 'تحقق من الرمز' : 'Vérifier'))
                            : (isAr ? 'إرسال الرمز' : 'Envoyer le code'),
                      ),
              ),
              if (_codeSent)
                TextButton(
                  onPressed:
                      auth.isLoading || _isSendingOtp || _remainingSeconds > 0
                      ? null
                      : _sendCode,
                  child: Text(
                    _remainingSeconds > 0
                        ? (isAr
                              ? 'يمكنك طلب رمز جديد بعد ${_formatRemaining()}'
                              : 'Nouveau code dans ${_formatRemaining()}')
                        : (isAr ? 'إعادة إرسال الرمز' : 'Renvoyer le code'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
