import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/delivery_locations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../../core/widgets/language_button.dart';
import '../providers/order_provider.dart';

class ClientNewOrderPage extends ConsumerStatefulWidget {
  final String serviceType;

  const ClientNewOrderPage({super.key, this.serviceType = 'delivery'});

  @override
  ConsumerState<ClientNewOrderPage> createState() => _ClientNewOrderPageState();
}

class _ClientNewOrderPageState extends ConsumerState<ClientNewOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  final _pickupFocusNode = FocusNode();
  final _deliveryFocusNode = FocusNode();

  double? get _trialPrice =>
      trialDeliveryPrice(_pickupCtrl.text, _deliveryCtrl.text);

  @override
  void dispose() {
    _descCtrl.dispose();
    _pickupCtrl.dispose();
    _deliveryCtrl.dispose();
    _pickupFocusNode.dispose();
    _deliveryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupCtrl.text.trim() == _deliveryCtrl.text.trim()) {
      final isAr = ref.read(localeProvider).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يجب أن تختلف نقطة الاستلام عن نقطة التوصيل'
                : 'Les points de départ et de livraison doivent être différents',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref
        .read(orderProvider.notifier)
        .createOrder(
          description: _descCtrl.text.trim(),
          pickupAddress: _pickupCtrl.text.trim(),
          deliveryAddress: _deliveryCtrl.text.trim(),
          serviceType: widget.serviceType,
        );
    if (success && mounted) {
      final isAr = ref.read(localeProvider).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تم إنشاء الطلب بنجاح!' : 'Commande créée avec succès !',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/client/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(orderProvider);
    final isCourse = widget.serviceType == 'course';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCourse
              ? (isAr ? 'طلب كورس' : 'Nouvelle course')
              : (isAr ? 'طلب توصيل' : 'Nouvelle livraison'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client'),
        ),
        actions: [const LanguageButton(), const LogoutButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Description
              _Section(
                title: isCourse
                    ? (isAr ? 'تفاصيل الكورس' : 'Détails de la course')
                    : (isAr ? 'وصف الطرد' : 'Description du colis'),
                child: TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isCourse
                        ? (isAr
                              ? 'اكتب ملاحظات عن المشوار'
                              : 'Notes sur le trajet')
                        : (isAr
                              ? 'ماذا تريد توصيله ؟'
                              : 'Que voulez-vous livrer ?'),
                    hintText: isAr
                        ? 'مثال: وثائق مهمة، طرد هش...'
                        : 'Ex: Documents importants, colis fragile...',
                    prefixIcon: Icon(
                      isCourse
                          ? Icons.directions_car_outlined
                          : Icons.inventory_2_outlined,
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? (isAr ? 'الوصف مطلوب' : 'Description requise')
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Pickup and delivery addresses
              _Section(
                title: isAr ? 'تفاصيل التوصيل' : 'Détails de livraison',
                child: Column(
                  children: [
                    _LocationSearchField(
                      controller: _pickupCtrl,
                      focusNode: _pickupFocusNode,
                      label: isAr ? 'نقطة الاستلام' : 'Point de ramassage',
                      hint: isAr
                          ? 'ابحث واختر نقطة الاستلام'
                          : 'Rechercher le point de ramassage',
                      icon: Icons.radio_button_checked,
                      iconColor: AppColors.success,
                      isAr: isAr,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    _LocationSearchField(
                      controller: _deliveryCtrl,
                      focusNode: _deliveryFocusNode,
                      label: isAr ? 'نقطة التوصيل' : 'Point de livraison',
                      hint: isAr
                          ? 'ابحث واختر نقطة التوصيل'
                          : 'Rechercher le point de livraison',
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.primary,
                      isAr: isAr,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              if (_trialPrice != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isAr
                            ? 'السعر: ${_trialPrice!.toStringAsFixed(0)} أوقية'
                            : 'Prix : ${_trialPrice!.toStringAsFixed(0)} MRU',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),

              ElevatedButton.icon(
                onPressed: state.isLoading ? null : _submit,
                icon: state.isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(isAr ? 'إرسال الطلب' : 'Envoyer la commande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LocationSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final bool isAr;
  final ValueChanged<String> onChanged;

  const _LocationSearchField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.isAr,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (option) => option,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return deliveryLocations;
        return deliveryLocations.where(
          (location) => location.toLowerCase().contains(query),
        );
      },
      onSelected: onChanged,
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          onChanged: onChanged,
          onFieldSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor),
            suffixIcon: const Icon(Icons.search_rounded),
          ),
          validator: (value) {
            final location = value?.trim() ?? '';
            if (location.isEmpty) {
              return isAr ? '$label مطلوبة' : '$label requis';
            }
            if (!deliveryLocations.contains(location)) {
              return isAr
                  ? 'اختر مكانًا من القائمة فقط'
                  : 'Choisissez uniquement un lieu de la liste';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final matches = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 260,
                maxWidth: MediaQuery.sizeOf(context).width - 64,
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: matches.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final location = matches[index];
                  return ListTile(
                    leading: Icon(icon, color: iconColor, size: 20),
                    title: Text(location, textAlign: TextAlign.right),
                    onTap: () => onSelected(location),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
