import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/merchant_product_model.dart';
import '../providers/merchant_provider.dart';
import '../widgets/merchant_widgets.dart';

class MerchantProductsPage extends ConsumerStatefulWidget {
  const MerchantProductsPage({super.key});

  @override
  ConsumerState<MerchantProductsPage> createState() =>
      _MerchantProductsPageState();
}

class _MerchantProductsPageState extends ConsumerState<MerchantProductsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(merchantProvider.notifier).loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(merchantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'المنتجات المتوفرة' : 'Produits disponibles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/merchant'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/merchant/products/add'),
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.products.isEmpty
          ? Center(child: Text(isAr ? 'لا توجد منتجات' : 'Aucun produit'))
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(merchantProvider.notifier).loadProducts(),
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: state.products.length,
                itemBuilder: (_, index) {
                  final product = state.products[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ProductImage(url: product.imageUrl),
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          InfoPill(
                            icon: Icons.payments_outlined,
                            label: '${product.price.toStringAsFixed(0)} MRU',
                            color: AppColors.success,
                          ),
                          InfoPill(
                            icon: Icons.inventory_outlined,
                            label:
                                '${isAr ? 'الكمية' : 'Qté'} ${product.quantity}',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditDialog(product, isAr),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _showEditDialog(MerchantProductModel product, bool isAr) async {
    final nameCtrl = TextEditingController(text: product.name);
    final priceCtrl = TextEditingController(
      text: product.price.toStringAsFixed(0),
    );
    final quantityCtrl = TextEditingController(
      text: product.quantity.toString(),
    );
    String? imagePath;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isAr ? 'تعديل المنتج' : 'Modifier le produit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final image = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      setDialogState(() => imagePath = image.path);
                    }
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    imagePath == null
                        ? (isAr ? 'تغيير الصورة' : 'Changer l’image')
                        : (isAr ? 'تم اختيار صورة' : 'Image choisie'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'اسم المنتج' : 'Nom',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'السعر' : 'Prix',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الكمية المتبقية' : 'Quantité restante',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(isAr ? 'إلغاء' : 'Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(isAr ? 'حفظ' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final error = await ref
        .read(merchantProvider.notifier)
        .saveProduct(
          id: product.id,
          name: nameCtrl.text.trim(),
          price: priceCtrl.text.trim(),
          quantity: quantityCtrl.text.trim(),
          imagePath: imagePath,
        );
    nameCtrl.dispose();
    priceCtrl.dispose();
    quantityCtrl.dispose();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? null : AppColors.error,
        content: Text(error ?? (isAr ? 'تم التعديل' : 'Produit modifié')),
      ),
    );
  }
}
