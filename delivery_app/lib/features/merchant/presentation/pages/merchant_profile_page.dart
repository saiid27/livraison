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
  final _methodNameCtrl = TextEditingController();
  final _methodPhoneCtrl = TextEditingController();
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authProvider).user;
      _contactCtrl.text = user?.merchantContactPhone ?? '';
      _paymentCtrl.text = user?.merchantPaymentPhone ?? '';
      ref.read(merchantProvider.notifier).loadPaymentMethods();
    });
  }

  @override
  void dispose() {
    _contactCtrl.dispose();
    _paymentCtrl.dispose();
    _methodNameCtrl.dispose();
    _methodPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(bool isAr) async {
    final currentAvatar = ref.read(authProvider).user?.avatar;
    if ((currentAvatar == null || currentAvatar.isEmpty) &&
        _avatarPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            isAr
                ? 'صورة البروفايل إلزامية'
                : 'La photo de profil est obligatoire',
          ),
        ),
      );
      return;
    }

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

  Future<void> _addPaymentMethod(bool isAr) async {
    if (_methodNameCtrl.text.trim().isEmpty ||
        _methodPhoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            isAr
                ? 'اكتب اسم طريقة الدفع ورقمها'
                : 'Ajoutez le nom et le numéro',
          ),
        ),
      );
      return;
    }

    final error = await ref
        .read(merchantProvider.notifier)
        .addPaymentMethod(
          name: _methodNameCtrl.text.trim(),
          phoneNumber: _methodPhoneCtrl.text.trim(),
        );
    if (!mounted) return;
    if (error == null) {
      _methodNameCtrl.clear();
      _methodPhoneCtrl.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? null : AppColors.error,
        content: Text(
          error ??
              (isAr ? 'تمت إضافة طريقة الدفع' : 'Moyen de paiement ajouté'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(merchantProvider);
    final methods = state.paymentMethods;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'ملف التاجر' : 'Profil commerçant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/merchant'),
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
          const SizedBox(height: 28),
          Text(
            isAr ? 'طرق الدفع' : 'Moyens de paiement',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _methodNameCtrl,
            decoration: InputDecoration(
              labelText: isAr ? 'اسم طريقة الدفع' : 'Nom du moyen',
              hintText: isAr ? 'مثال: بنكيلي' : 'Ex: Bankily',
              prefixIcon: const Icon(Icons.credit_card_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _methodPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: isAr ? 'رقم الدفع' : 'Numéro de paiement',
              prefixIcon: const Icon(Icons.phone_android_outlined),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: state.isSubmitting
                ? null
                : () => _addPaymentMethod(isAr),
            icon: const Icon(Icons.add_card_outlined),
            label: Text(isAr ? 'إضافة طريقة دفع' : 'Ajouter un moyen'),
          ),
          const SizedBox(height: 12),
          if (methods.isEmpty)
            Text(
              isAr
                  ? 'لم تتم إضافة طرق دفع بعد'
                  : 'Aucun moyen de paiement ajouté',
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else
            ...methods.map(
              (method) => Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(method.name),
                  subtitle: Text(method.phoneNumber),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
