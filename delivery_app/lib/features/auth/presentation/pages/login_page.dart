import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/language_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authProvider.notifier)
        .login(_phoneCtrl.text.trim(), _passwordCtrl.text);
    if (success && mounted) {
      final role = ref.read(authProvider).role;
      final approvalStatus = ref.read(authProvider).approvalStatus;
      final route = switch (role) {
        AppConstants.roleClient => '/client',
        AppConstants.roleLivreur =>
          approvalStatus == 'approved' ? '/livreur' : '/captain-pending',
        AppConstants.roleCarCaptain =>
          approvalStatus == 'approved' ? '/car-captain' : '/captain-pending',
        AppConstants.roleMerchant => '/merchant',
        AppConstants.roleAdmin => '/admin',
        _ => '/login',
      };
      context.go(route);
    }
  }

  List<_LoginInfoLink> _infoLinks(bool isAr) => [
    _LoginInfoLink(title: isAr ? 'من نحن' : 'À propos', route: '/about'),
    _LoginInfoLink(
      title: isAr ? 'سياسة الخصوصية' : 'Confidentialité',
      route: '/privacy',
    ),
    _LoginInfoLink(title: isAr ? 'تواصل معنا' : 'Contact', route: '/contact'),
    _LoginInfoLink(
      title: isAr ? 'طلب حذف حسابي' : 'Supprimer mon compte',
      route: '/delete-account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';
    final infoLinks = _infoLinks(isAr);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isShort = constraints.maxHeight < 680;
            final pagePadding = isShort ? 14.0 : 20.0;
            final logoSize = isShort ? 88.0 : 122.0;

            return SingleChildScrollView(
              padding: EdgeInsets.all(pagePadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > pagePadding * 2
                      ? constraints.maxHeight - (pagePadding * 2)
                      : 0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isShort ? 2 : 8),
                      Center(
                        child: Container(
                          width: logoSize,
                          height: logoSize,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              isShort ? 22 : 28,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/login_logo.svg',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: isShort ? 10 : 16),
                      Text(
                        s.welcome,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isShort ? 22 : 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: isShort ? 4 : 6),
                      Text(
                        s.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isShort ? 13 : 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: isShort ? 16 : 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: s.phone,
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return s.phoneRequired;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isShort ? 10 : 14),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: s.password,
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return s.passwordRequired;
                                }
                                if (v.length < 6) {
                                  return s.passwordMin;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isShort ? 12 : 16),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  visualDensity: isShort
                                      ? VisualDensity.compact
                                      : VisualDensity.standard,
                                ),
                                onPressed: () => context.go('/forgot-password'),
                                child: Text(
                                  locale.languageCode == 'ar'
                                      ? 'نسيت كلمة المرور؟'
                                      : 'Mot de passe oublié ?',
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: authState.isLoading ? null : _login,
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(s.loginBtn),
                            ),
                            if (authState.error != null) ...[
                              SizedBox(height: isShort ? 8 : 12),
                              Container(
                                padding: EdgeInsets.all(isShort ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  authState.error!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            SizedBox(height: isShort ? 0 : 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  s.noAccount,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    visualDensity: isShort
                                        ? VisualDensity.compact
                                        : VisualDensity.standard,
                                  ),
                                  onPressed: () => context.go('/register'),
                                  child: Text(s.registerLink),
                                ),
                              ],
                            ),
                            SizedBox(height: isShort ? 8 : 10),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.go('/client/marketplace'),
                              icon: const Icon(Icons.storefront_outlined),
                              label: Text(
                                isAr
                                    ? 'تصفح المنتجات'
                                    : 'Parcourir les produits',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isShort ? 0 : 4),
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final item in infoLinks) ...[
                                _LoginInfoLinkText(
                                  item: item,
                                  onTap: () => context.push(item.route),
                                ),
                                if (item != infoLinks.last)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '|',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isShort ? 6 : 12),
                      Center(
                        child: Column(
                          children: [
                            const LanguageButton(color: AppColors.primary),
                            SizedBox(height: isShort ? 8 : 14),
                            const Text(
                              'mayahsar @2026 | dev. med said mohameden',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginInfoLink {
  const _LoginInfoLink({required this.title, required this.route});

  final String title;
  final String route;
}

class _LoginInfoLinkText extends StatelessWidget {
  const _LoginInfoLinkText({required this.item, required this.onTap});

  final _LoginInfoLink item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          item.title,
          maxLines: 1,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
