import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/merchant_provider.dart';

class MerchantProfilePage extends ConsumerStatefulWidget {
  const MerchantProfilePage({super.key});

  @override
  ConsumerState<MerchantProfilePage> createState() =>
      _MerchantProfilePageState();
}

class _MerchantProfilePageState extends ConsumerState<MerchantProfilePage> {
  final _contactCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      _contactCtrl.text = user?.merchantContactPhone ?? '';
      _paymentCtrl.text = user?.merchantPaymentPhone ?? '';
    });
  }

  @override
  void dispose() {
    _contactCtrl.dispose();
    _paymentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(bool isAr) async {
    final error = await ref
        .read(merchantProvider.notifier)
        .updateProfile(
          contactPhone: _contactCtrl.text.trim(),
          paymentPhone: _paymentCtrl.text.trim(),
          avatarPath: _avatarPath,
        );
    await ref.read(authProvider.notifier).refreshProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? null : AppColors.error,
        content: Text(error ?? (isAr ? 'تم حفظ الملف' : 'Profil enregistré')),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) setState(() => _avatarPath = image.path);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(merchantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'ملف التاجر' : 'Profil commerçant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/merchant'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          OutlinedButton.icon(
            onPressed: _pickAvatar,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              _avatarPath == null
                  ? (isAr ? 'اختيار صورة البروفايل' : 'Choisir une photo')
                  : (isAr ? 'تم اختيار الصورة' : 'Photo choisie'),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _contactCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: isAr ? 'رقم التواصل' : 'Téléphone de contact',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _paymentCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: isAr ? 'رقم الدفع' : 'Numéro de paiement',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: state.isSubmitting ? null : () => _save(isAr),
            icon: const Icon(Icons.save_outlined),
            label: Text(isAr ? 'حفظ' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}
