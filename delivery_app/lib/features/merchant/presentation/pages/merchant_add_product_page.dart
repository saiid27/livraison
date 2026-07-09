import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/merchant_provider.dart';

class MerchantAddProductPage extends ConsumerStatefulWidget {
  const MerchantAddProductPage({super.key});

  @override
  ConsumerState<MerchantAddProductPage> createState() =>
      _MerchantAddProductPageState();
}

class _MerchantAddProductPageState
    extends ConsumerState<MerchantAddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  String? _imagePath;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) setState(() => _imagePath = image.path);
  }

  Future<void> _submit(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            isAr ? 'يرجى اختيار صورة المنتج' : 'Veuillez choisir une image',
          ),
        ),
      );
      return;
    }
    final error = await ref
        .read(merchantProvider.notifier)
        .saveProduct(
          name: _nameCtrl.text.trim(),
          price: _priceCtrl.text.trim(),
          quantity: _quantityCtrl.text.trim(),
          imagePath: _imagePath,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? null : AppColors.error,
        content: Text(error ?? (isAr ? 'تمت إضافة المنتج' : 'Produit ajouté')),
      ),
    );
    if (error == null) context.go('/merchant/products');
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(merchantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إضافة منتج' : 'Ajouter un produit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/merchant'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _imagePath == null
                      ? (isAr ? 'اختيار صورة المنتج' : 'Choisir une image')
                      : (isAr ? 'تم اختيار الصورة' : 'Image choisie'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'اسم المنتج' : 'Nom du produit',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? (isAr ? 'اسم المنتج مطلوب' : 'Nom requis')
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'السعر' : 'Prix',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? (isAr ? 'السعر مطلوب' : 'Prix requis')
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'الكمية المتوفرة' : 'Quantité disponible',
                  prefixIcon: const Icon(Icons.numbers_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? (isAr ? 'الكمية مطلوبة' : 'Quantité requise')
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: state.isSubmitting ? null : () => _submit(isAr),
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isAr ? 'حفظ المنتج' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
