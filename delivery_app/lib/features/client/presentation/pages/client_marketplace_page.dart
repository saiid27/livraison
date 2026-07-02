import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../merchant/data/models/merchant_product_model.dart';
import '../../../merchant/presentation/widgets/merchant_widgets.dart';
import '../providers/marketplace_provider.dart';

class ClientMarketplacePage extends ConsumerStatefulWidget {
  const ClientMarketplacePage({super.key});

  @override
  ConsumerState<ClientMarketplacePage> createState() =>
      _ClientMarketplacePageState();
}

class _ClientMarketplacePageState extends ConsumerState<ClientMarketplacePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(marketplaceProvider.notifier).loadProducts(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(marketplaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'منتجات التجار' : 'Produits'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client'),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.products.isEmpty
          ? Center(child: Text(isAr ? 'لا توجد منتجات' : 'Aucun produit'))
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(marketplaceProvider.notifier).loadProducts(),
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: state.products.length,
                itemBuilder: (_, index) =>
                    _ProductCard(product: state.products[index], isAr: isAr),
              ),
            ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product, required this.isAr});

  final MerchantProductModel product;
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitting = ref.watch(marketplaceProvider).isSubmitting;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProductImage(url: product.imageUrl, size: 80),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          InfoPill(
                            icon: Icons.storefront_outlined,
                            label: product.merchantName ?? '—',
                            color: AppColors.primary,
                          ),
                          InfoPill(
                            icon: Icons.payments_outlined,
                            label: '${product.price.toStringAsFixed(0)} MRU',
                            color: AppColors.success,
                          ),
                          InfoPill(
                            icon: Icons.inventory_outlined,
                            label:
                                '${isAr ? 'متوفر' : 'Stock'} ${product.quantity}',
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _paymentInfo,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: submitting ? null : () => _buy(context, ref),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(isAr ? 'شراء' : 'Acheter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final quantityCtrl = TextEditingController(text: '1');
    final quantity = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'شراء المنتج' : 'Acheter le produit'),
        content: TextField(
          controller: quantityCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: isAr ? 'الكمية' : 'Quantité'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إلغاء' : 'Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(quantityCtrl.text) ?? 0),
            child: Text(isAr ? 'تأكيد' : 'Confirmer'),
          ),
        ],
      ),
    );
    quantityCtrl.dispose();
    if (quantity == null || quantity <= 0) return;

    final error = await ref
        .read(marketplaceProvider.notifier)
        .buyProduct(product.id, quantity);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error == null ? null : AppColors.error,
        content: Text(
          error ?? (isAr ? 'تم إرسال الطلب للتاجر' : 'Commande envoyée'),
        ),
      ),
    );
  }

  String get _paymentInfo {
    final contact = product.merchantContactPhone ?? (isAr ? 'غير محدد' : '—');
    final methods = product.merchantPaymentMethods;
    if (methods.isNotEmpty) {
      final lines = methods
          .map((method) => '${method.name}: ${method.phoneNumber}')
          .join('\n');
      return isAr
          ? 'طرق الدفع:\n$lines\nالتواصل: $contact'
          : 'Moyens de paiement:\n$lines\nContact: $contact';
    }
    final payment = product.merchantPaymentPhone ?? (isAr ? 'غير محدد' : '—');
    return isAr
        ? 'رقم الدفع: $payment | التواصل: $contact'
        : 'Paiement: $payment | Contact: $contact';
  }
}
