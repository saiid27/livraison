import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../merchant/data/models/merchant_order_model.dart';
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
  MarketplaceMerchantModel? _selectedMerchant;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(marketplaceProvider.notifier).loadMerchants(),
    );
  }

  Future<void> _selectMerchant(MarketplaceMerchantModel merchant) async {
    setState(() => _selectedMerchant = merchant);
    await ref
        .read(marketplaceProvider.notifier)
        .loadProducts(merchantId: merchant.id);
  }

  Future<void> _refresh() {
    final merchant = _selectedMerchant;
    if (merchant == null) {
      return ref.read(marketplaceProvider.notifier).loadMerchants();
    }
    return ref
        .read(marketplaceProvider.notifier)
        .loadProducts(merchantId: merchant.id);
  }

  void _goBack() {
    if (_selectedMerchant != null) {
      setState(() => _selectedMerchant = null);
      return;
    }
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    context.go(isAuthenticated ? '/client' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(marketplaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedMerchant == null
              ? (isAr ? 'المؤسسات' : 'Boutiques')
              : _selectedMerchant!.name,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedMerchant == null
          ? _MerchantsList(
              merchants: state.merchants,
              isAr: isAr,
              onRefresh: _refresh,
              onSelect: _selectMerchant,
            )
          : state.products.isEmpty
          ? Center(child: Text(isAr ? 'لا توجد منتجات' : 'Aucun produit'))
          : RefreshIndicator(
              onRefresh: _refresh,
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

class _MerchantsList extends StatelessWidget {
  const _MerchantsList({
    required this.merchants,
    required this.isAr,
    required this.onRefresh,
    required this.onSelect,
  });

  final List<MarketplaceMerchantModel> merchants;
  final bool isAr;
  final Future<void> Function() onRefresh;
  final ValueChanged<MarketplaceMerchantModel> onSelect;

  @override
  Widget build(BuildContext context) {
    if (merchants.isEmpty) {
      return Center(child: Text(isAr ? 'لا توجد مؤسسات' : 'Aucune boutique'));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: merchants.length,
        itemBuilder: (_, index) => _MerchantCard(
          merchant: merchants[index],
          isAr: isAr,
          onTap: () => onSelect(merchants[index]),
        ),
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({
    required this.merchant,
    required this.isAr,
    required this.onTap,
  });

  final MarketplaceMerchantModel merchant;
  final bool isAr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contact = merchant.contactPhone?.trim().isNotEmpty == true
        ? merchant.contactPhone!.trim()
        : (isAr ? 'غير محدد' : 'Non défini');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ProductImage(url: merchant.avatarUrl, size: 76),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        InfoPill(
                          icon: Icons.inventory_2_outlined,
                          label:
                              '${merchant.productCount} ${isAr ? 'منتج' : 'produits'}',
                          color: AppColors.primary,
                        ),
                        InfoPill(
                          icon: Icons.phone_outlined,
                          label: contact,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isAr ? Icons.chevron_left : Icons.chevron_right,
                color: AppColors.primary,
                size: 32,
              ),
            ],
          ),
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
    final authState = ref.watch(authProvider);
    final canOrder =
        authState.isAuthenticated && authState.role == AppConstants.roleClient;

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
                onPressed: submitting
                    ? null
                    : () => canOrder
                          ? _buy(context, ref)
                          : _requireClientLogin(context, authState.role),
                icon: Icon(
                  canOrder ? Icons.shopping_bag_outlined : Icons.login_outlined,
                ),
                label: Text(
                  canOrder
                      ? (isAr ? 'شراء' : 'Acheter')
                      : (isAr ? 'سجل الدخول للطلب' : 'Connexion requise'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final order = await showModalBottomSheet<MerchantOrderModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PurchaseForm(product: product, isAr: isAr),
    );
    if (!context.mounted || order == null) return;
    await _showConfirmation(context, order);
  }

  Future<void> _requireClientLogin(BuildContext context, String? role) async {
    final isLoggedInAsOtherRole =
        role != null && role != AppConstants.roleClient;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline, color: AppColors.primary),
        title: Text(isAr ? 'تسجيل الدخول مطلوب' : 'Connexion requise'),
        content: Text(
          isLoggedInAsOtherRole
              ? (isAr
                    ? 'الطلب متاح لحسابات الزبائن فقط.'
                    : 'La commande est réservée aux comptes client.')
              : (isAr
                    ? 'يمكنك تصفح المنتجات الآن، لكن يجب تسجيل الدخول قبل إرسال طلب.'
                    : 'Vous pouvez parcourir les produits, mais vous devez vous connecter avant de commander.'),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isLoggedInAsOtherRole
                  ? (isAr ? 'إغلاق' : 'Fermer')
                  : (isAr ? 'لاحقًا' : 'Plus tard'),
            ),
          ),
          if (!isLoggedInAsOtherRole)
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/login');
              },
              child: Text(isAr ? 'تسجيل الدخول' : 'Se connecter'),
            ),
        ],
      ),
    );
  }

  Future<void> _showConfirmation(
    BuildContext context,
    MerchantOrderModel order,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: AppColors.success,
          size: 48,
        ),
        title: Text(isAr ? 'تم إرسال الطلب' : 'Commande envoyée'),
        content: Text(
          isAr
              ? 'طلبك قيد المراجعة الآن. سيتم إعلامك عند تأكيده من طرف التاجر.'
              : 'Votre commande est en cours de vérification. Vous serez informé dès sa confirmation par le vendeur.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _contactOnWhatsApp(context, order);
              },
              icon: const Text('📱', style: TextStyle(fontSize: 16)),
              label: Text(
                isAr
                    ? 'تواصل مع التاجر عبر واتساب'
                    : 'Contacter le vendeur sur WhatsApp',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إغلاق' : 'Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _contactOnWhatsApp(
    BuildContext context,
    MerchantOrderModel order,
  ) async {
    final vendorPhone = (order.merchantContactPhone?.trim().isNotEmpty == true)
        ? order.merchantContactPhone!.trim()
        : order.merchantPaymentPhone?.trim();
    if (vendorPhone == null || vendorPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'رقم التاجر غير متوفر'
                : "Le numéro du vendeur n'est pas disponible",
          ),
        ),
      );
      return;
    }

    final digits = vendorPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = isAr
        ? 'مرحباً، أنا ${order.buyerName ?? ''}، أرسلت طلب رقم #${order.id} '
              'وقمت بالدفع من الرقم ${order.paymentPhoneFrom ?? ''}. أرجو التأكيد.'
        : 'Bonjour, je suis ${order.buyerName ?? ''}, j\'ai passé la commande '
              '#${order.id} et payé depuis le numéro ${order.paymentPhoneFrom ?? ''}. '
              'Merci de confirmer.';
    final uri = Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تعذر فتح واتساب' : "Impossible d'ouvrir WhatsApp",
          ),
        ),
      );
    }
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

class _PurchaseForm extends ConsumerStatefulWidget {
  const _PurchaseForm({required this.product, required this.isAr});

  final MerchantProductModel product;
  final bool isAr;

  @override
  ConsumerState<_PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends ConsumerState<_PurchaseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _nameCtrl;
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _screenshotPath;

  bool get isAr => widget.isAr;

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController(text: '1');
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) setState(() => _screenshotPath = image.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_screenshotPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى إرفاق صورة إثبات الدفع'
                : 'Veuillez joindre la preuve de paiement',
          ),
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final order = await ref
        .read(marketplaceProvider.notifier)
        .buyProduct(
          productId: widget.product.id,
          merchantId: widget.product.merchantId,
          quantity: quantity,
          buyerName: _nameCtrl.text.trim(),
          paymentPhoneFrom: _phoneCtrl.text.trim(),
          screenshotPath: _screenshotPath!,
          notes: _notesCtrl.text.trim(),
        );

    if (!mounted) return;
    if (order == null) {
      final error = ref.read(marketplaceProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(error ?? (isAr ? 'خطأ' : 'Erreur')),
        ),
      );
      return;
    }
    Navigator.of(context).pop(order);
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(marketplaceProvider).isSubmitting;

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAr ? 'تأكيد الشراء' : 'Confirmer l\'achat',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.name,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'الكمية' : 'Quantité',
                  prefixIcon: const Icon(Icons.numbers_outlined),
                ),
                validator: (value) {
                  final qty = int.tryParse(value?.trim() ?? '');
                  if (qty == null || qty <= 0) {
                    return isAr ? 'كمية غير صحيحة' : 'Quantité invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'اسم العميل' : 'Nom du client',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? (isAr ? 'الاسم مطلوب' : 'Nom requis')
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isAr
                      ? 'رقم الهاتف المستخدم للدفع'
                      : 'Téléphone utilisé pour le paiement',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  final phone = value?.trim() ?? '';
                  if (phone.isEmpty) {
                    return isAr ? 'الرقم مطلوب' : 'Numéro requis';
                  }
                  if (!RegExp(r'^[0-9+ ]{8,15}$').hasMatch(phone)) {
                    return isAr ? 'رقم غير صحيح' : 'Numéro invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _screenshotPath == null
                      ? (isAr
                            ? 'إرفاق صورة إثبات الدفع'
                            : 'Joindre la preuve de paiement')
                      : (isAr ? 'تم اختيار الصورة' : 'Image sélectionnée'),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isAr
                      ? 'ملاحظات إضافية (اختياري)'
                      : 'Remarques supplémentaires (optionnel)',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: submitting ? null : _submit,
                icon: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(isAr ? 'إرسال الطلب' : 'Envoyer la commande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
