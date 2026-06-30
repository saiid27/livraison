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
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _codeSent = false;
  bool _obscurePassword = true;
  String? _developmentCode;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _message(
        isAr ? 'أدخل بريدًا إلكترونيًا صحيحًا' : 'Saisissez un email valide',
      );
      return;
    }
    final code = await ref
        .read(authProvider.notifier)
        .requestPasswordReset(email);
    if (!mounted || ref.read(authProvider).error != null) return;
    setState(() {
      _codeSent = true;
      _developmentCode = code;
      if (code != null) _codeController.text = code;
    });
    _message(isAr ? 'تم إرسال رمز التحقق' : 'Code de vérification envoyé');
  }

  Future<void> _resetPassword() async {
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    if (_codeController.text.trim().length != 6) {
      _message(
        isAr
            ? 'أدخل رمز التحقق المكون من 6 أرقام'
            : 'Saisissez le code à 6 chiffres',
      );
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
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          password: _passwordController.text,
        );
    if (success && mounted) {
      _message(isAr ? 'تم تغيير كلمة المرور بنجاح' : 'Mot de passe modifié');
      context.go('/login');
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
                    ? (isAr
                          ? 'أدخل رمز التحقق وكلمة المرور الجديدة'
                          : 'Saisissez le code et le nouveau mot de passe')
                    : (isAr
                          ? 'أدخل بريد حسابك وسنرسل لك رمز التحقق'
                          : 'Saisissez votre email pour recevoir un code'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                readOnly: _codeSent,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: isAr ? 'البريد الإلكتروني' : 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                if (_developmentCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      isAr
                          ? 'رمز التطوير: $_developmentCode'
                          : 'Code de développement : $_developmentCode',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: isAr ? 'رمز التحقق' : 'Code de vérification',
                    prefixIcon: const Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                ),
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                            ? (isAr
                                  ? 'تغيير كلمة المرور'
                                  : 'Modifier le mot de passe')
                            : (isAr ? 'إرسال الرمز' : 'Envoyer le code'),
                      ),
              ),
              if (_codeSent)
                TextButton(
                  onPressed: auth.isLoading ? null : _sendCode,
                  child: Text(isAr ? 'إعادة إرسال الرمز' : 'Renvoyer le code'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
