import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/language_button.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _picker = ImagePicker();
  final Map<String, XFile> _captainDocuments = {};
  bool _obscurePassword = true;
  String _selectedRole = AppConstants.roleClient;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(String key) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (image != null && mounted) {
      setState(() => _captainDocuments[key] = image);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final isAr = ref.read(localeProvider).languageCode == 'ar';
    if (_selectedRole == AppConstants.roleLivreur &&
        _captainDocuments.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى رفع جميع صور ومستندات الكابتن'
                : 'Veuillez ajouter tous les documents du capitaine',
          ),
        ),
      );
      return;
    }
    if (_selectedRole == AppConstants.roleMerchant &&
        !_captainDocuments.containsKey('profile_image')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى رفع صورة المؤسسة'
                : 'Veuillez ajouter la photo de la boutique',
          ),
        ),
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .register(
          name: _nameCtrl.text.trim(),
          password: _passwordCtrl.text,
          phone: _phoneCtrl.text.trim(),
          role: _selectedRole,
          captainDocuments: _captainDocuments.map(
            (key, file) => MapEntry(key, file.path),
          ),
        );
    if (success && mounted) {
      final route = switch (_selectedRole) {
        AppConstants.roleClient => '/client',
        AppConstants.roleLivreur => '/captain-pending',
        AppConstants.roleMerchant => '/merchant',
        _ => '/login',
      };
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isAr ? Icons.arrow_forward : Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.go('/login'),
        ),
        actions: const [LanguageButton(color: AppColors.primary)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.createAccount,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.registerSubtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isAr ? 'نوع الحساب' : 'Type de compte',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.45,
                  children: [
                    _RoleCard(
                      title: isAr ? 'زبون' : 'Client',
                      icon: Icons.person_outline_rounded,
                      selected: _selectedRole == AppConstants.roleClient,
                      onTap: () => setState(
                        () => _selectedRole = AppConstants.roleClient,
                      ),
                    ),
                    _RoleCard(
                      title: isAr ? 'كابتن توصيل' : 'Capitaine livraison',
                      icon: Icons.delivery_dining_outlined,
                      selected: _selectedRole == AppConstants.roleLivreur,
                      onTap: () => setState(
                        () => _selectedRole = AppConstants.roleLivreur,
                      ),
                    ),
                    _RoleCard(
                      title: isAr ? 'تاجر' : 'Commerçant',
                      icon: Icons.storefront_outlined,
                      selected: _selectedRole == AppConstants.roleMerchant,
                      onTap: () => setState(
                        () => _selectedRole = AppConstants.roleMerchant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: s.fullName,
                    prefixIcon: const Icon(Icons.person_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? s.nameRequired : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: s.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? s.phoneRequired : null,
                ),
                const SizedBox(height: 14),
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return s.passwordRequired;
                    }
                    if (value.length < 6) return s.passwordMin;
                    return null;
                  },
                ),
                if (_selectedRole == AppConstants.roleLivreur) ...[
                  const SizedBox(height: 24),
                  _CaptainDocuments(
                    isArabic: isAr,
                    selected: _captainDocuments,
                    onPick: _pickDocument,
                  ),
                ],
                if (_selectedRole == AppConstants.roleMerchant) ...[
                  const SizedBox(height: 24),
                  _MerchantProfileImage(
                    isArabic: isAr,
                    selected: _captainDocuments['profile_image'],
                    onPick: () => _pickDocument('profile_image'),
                  ),
                ],
                if (authState.error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _register,
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(s.registerBtn),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.alreadyAccount,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(s.loginLink),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptainDocuments extends StatelessWidget {
  final bool isArabic;
  final Map<String, XFile> selected;
  final ValueChanged<String> onPick;

  const _CaptainDocuments({
    required this.isArabic,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final documents = <(String, String, IconData)>[
      (
        'profile_image',
        isArabic ? 'صورتك الشخصية' : 'Photo de profil',
        Icons.account_circle_outlined,
      ),
      (
        'id_card_image',
        isArabic ? 'بطاقة التعريف' : "Pièce d'identité",
        Icons.badge_outlined,
      ),
      (
        'vehicle_image',
        isArabic ? 'صورة الدراجة' : 'Photo de la moto',
        Icons.two_wheeler_outlined,
      ),
      (
        'vehicle_registration_image',
        isArabic ? 'تسجيل الدراجة' : 'Carte grise',
        Icons.description_outlined,
      ),
      (
        'permit_image',
        isArabic ? 'التصريح' : 'Autorisation',
        Icons.verified_user_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isArabic ? 'وثائق الكابتن' : 'Documents du capitaine',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          isArabic
              ? 'جميع الصور مطلوبة لمراجعة الحساب من الإدارة'
              : "Toutes les images sont requises pour la validation",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...documents.map((document) {
          final (key, label, icon) = document;
          final isSelected = selected.containsKey(key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: isSelected
                  ? AppColors.success.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onPick(key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.success : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : icon,
                        color: isSelected
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.edit_outlined : Icons.upload_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MerchantProfileImage extends StatelessWidget {
  final bool isArabic;
  final XFile? selected;
  final VoidCallback onPick;

  const _MerchantProfileImage({
    required this.isArabic,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isArabic ? 'صورة المؤسسة' : 'Photo de la boutique',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          isArabic
              ? 'ستظهر هذه الصورة للزبائن في صفحة المؤسسات'
              : 'Cette photo sera affichée aux clients dans la liste des boutiques',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Material(
          color: isSelected
              ? AppColors.success.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.success
                      : AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_outline
                        : Icons.storefront_outlined,
                    color: isSelected ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSelected
                          ? (isArabic ? 'تم اختيار الصورة' : 'Photo choisie')
                          : (isArabic
                                ? 'اختيار صورة المؤسسة'
                                : 'Choisir la photo'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.primary,
              size: 27,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
