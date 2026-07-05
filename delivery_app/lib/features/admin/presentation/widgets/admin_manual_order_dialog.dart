import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/delivery_locations.dart';
import '../../../../core/providers/delivery_locations_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/admin_provider.dart';

class AdminManualOrderDialog extends ConsumerStatefulWidget {
  const AdminManualOrderDialog({super.key});

  @override
  ConsumerState<AdminManualOrderDialog> createState() =>
      _AdminManualOrderDialogState();
}

class _AdminManualOrderDialogState
    extends ConsumerState<AdminManualOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _isSubmitting = false;
  double? _trialPrice;
  int _priceLookupVersion = 0;

  Future<void> _updateTrialPrice(List<String> locations) async {
    final lookupVersion = ++_priceLookupVersion;
    final pickup = _pickupCtrl.text.trim();
    final delivery = _deliveryCtrl.text.trim();
    final fallbackPrice = localDeliveryPriceFor(pickup, delivery, locations);

    if (fallbackPrice == null) {
      if (_trialPrice != null) setState(() => _trialPrice = null);
      return;
    }

    if (_trialPrice != fallbackPrice) {
      setState(() => _trialPrice = fallbackPrice);
    }

    final remotePrice = await fetchDeliveryPrice(pickup, delivery);
    if (!mounted || lookupVersion != _priceLookupVersion) return;
    if (remotePrice != null && remotePrice != _trialPrice) {
      setState(() => _trialPrice = remotePrice);
    }
  }

  double? get _customPrice {
    final raw = _priceCtrl.text.trim().replaceAll(',', '.');
    return raw.isEmpty ? null : double.tryParse(raw);
  }

  bool get _needsCustomPrice =>
      _pickupCtrl.text.trim().isNotEmpty &&
      _deliveryCtrl.text.trim().isNotEmpty &&
      _trialPrice == null;

  @override
  void dispose() {
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _pickupCtrl.dispose();
    _deliveryCtrl.dispose();
    _priceCtrl.dispose();
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
                : 'Les points doivent être différents',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await ref
        .read(adminProvider.notifier)
        .createManualOrder(
          description: _descCtrl.text.trim(),
          pickupAddress: _pickupCtrl.text.trim(),
          deliveryAddress: _deliveryCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim(),
          customerName: _nameCtrl.text.trim(),
          price: _needsCustomPrice ? _customPrice : null,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (error == null) {
      Navigator.of(context).pop(true);
      final isAr = ref.read(localeProvider).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم إرسال الطلب' : 'Commande envoyée'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final trialPrice = _trialPrice;
    final locationState = ref.watch(deliveryLocationListProvider);
    final locations = locationState.value ?? deliveryLocations;

    return AlertDialog(
      title: Text(isAr ? 'إرسال طلب توصيل' : 'Créer une livraison'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isAr ? 'رقم الزبون' : 'Téléphone client',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? (isAr ? 'رقم الزبون مطلوب' : 'Téléphone requis')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: isAr
                      ? 'اسم الزبون اختياري'
                      : 'Nom client optionnel',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              _LocationTextField(
                controller: _pickupCtrl,
                isAr: isAr,
                label: isAr ? 'نقطة الاستلام' : 'Point de départ',
                icon: Icons.radio_button_checked,
                locations: locations,
                onChanged: (_) => _updateTrialPrice(locations),
              ),
              const SizedBox(height: 12),
              _LocationTextField(
                controller: _deliveryCtrl,
                isAr: isAr,
                label: isAr ? 'نقطة التوصيل' : 'Destination',
                icon: Icons.location_on_outlined,
                locations: locations,
                onChanged: (_) => _updateTrialPrice(locations),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isAr ? 'تفاصيل الطلب' : 'Détails',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? (isAr ? 'التفاصيل مطلوبة' : 'Détails requis')
                    : null,
              ),
              const SizedBox(height: 12),
              if (trialPrice != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    isAr
                        ? 'السعر: ${trialPrice.toStringAsFixed(0)} أوقية'
                        : 'Prix : ${trialPrice.toStringAsFixed(0)} MRU',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else if (_needsCustomPrice)
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: isAr ? 'السعر الخاص' : 'Prix spécial',
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    if (!_needsCustomPrice) return null;
                    final price = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );
                    if (price == null || price <= 0) {
                      return isAr ? 'السعر مطلوب' : 'Prix requis';
                    }
                    return null;
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(isAr ? 'إلغاء' : 'Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Text(isAr ? 'إرسال' : 'Envoyer'),
        ),
      ],
    );
  }
}

class _LocationTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool isAr;
  final String label;
  final IconData icon;
  final List<String> locations;
  final ValueChanged<String> onChanged;

  const _LocationTextField({
    required this.controller,
    required this.isAr,
    required this.label,
    required this.icon,
    required this.locations,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down),
          onSelected: (value) {
            controller.text = value;
            onChanged(value);
          },
          itemBuilder: (_) => locations
              .map(
                (location) =>
                    PopupMenuItem(value: location, child: Text(location)),
              )
              .toList(),
        ),
      ),
      validator: (value) => value == null || value.trim().isEmpty
          ? (isAr ? '$label مطلوبة' : '$label requis')
          : null,
    );
  }
}
