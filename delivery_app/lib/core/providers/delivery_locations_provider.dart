import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/delivery_locations.dart';
import '../network/api_client.dart';

const _toujounineTensouelimPrice = 120.0;
const _toujounineDarNaimPrice = 130.0;
const _toujounineNaibPrice = 100.0;
const _toujounineEtihadiaPrice = 150.0;
const _toujounineTeyaretPrice = 150.0;
const _toujounineMadridPrice = 120.0;
const _toujounineArafatPrice = 130.0;
const _toujounineFalloujaPrice = 120.0;
const _toujounineMelahPrice = 100.0;
const _toujounineTarhilPrice = 150.0;
const _toujounineBeikaPrice = 150.0;
const _toujounineAfarcoPrice = 120.0;
const _toujounineBmdPrice = 140.0;
const _toujounineDarSalamaPrice = 180.0;
const _toujounineTwentyFourthPrice = 110.0;

final deliveryLocationListProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final refreshTimer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
  ref.onDispose(refreshTimer.cancel);

  try {
    final response = await ApiClient.instance.get('/client/delivery-locations');
    final data = response.data;
    final rawLocations = data is Map ? data['locations'] : null;
    if (rawLocations is List) {
      final locations = rawLocations
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (locations.isNotEmpty) return locations;
    }
  } catch (_) {
    // Keep the app usable if the backend is waking up or offline.
  }
  return deliveryLocations;
});

bool _isToujounineLocation(String name) {
  final value = name.trim();
  return value.startsWith('توجونين') ||
      value.startsWith('تجونين') ||
      value.startsWith('توجنين');
}

bool _isTensouelimLocation(String name) {
  final value = name.trim();
  return value.startsWith('تنسويلم') ||
      value.startsWith('كرفور تنسويلم') ||
      value.startsWith('كروفور تنسويلم');
}

bool _isDarNaimLocation(String name) {
  final value = name.trim();
  return value.startsWith('دار النعيم') || value.startsWith('دار النعيم-');
}

bool _isNaibLocation(String name) {
  final value = name.trim();
  return value.startsWith('النائب') ||
      value.startsWith('النايب') ||
      value.startsWith('كرفور النائب') ||
      value.startsWith('كرفور النايب') ||
      value.contains('النائب') ||
      value.contains('النايب');
}

bool _hasLocationTerm(String name, List<String> terms) {
  final value = name.trim().toLowerCase();
  return terms.any((term) => value.contains(term.toLowerCase()));
}

bool _isEtihadiaLocation(String name) => _hasLocationTerm(name, ['الاتحادية']);

bool _isTeyaretLocation(String name) =>
    _hasLocationTerm(name, ['تيارت', 'تيرات']);

bool _isMadridLocation(String name) => _hasLocationTerm(name, ['مدريد']);

bool _isArafatLocation(String name) =>
    _hasLocationTerm(name, ['عرفات', 'عرفاات']);

bool _isFalloujaLocation(String name) => _hasLocationTerm(name, ['الفلوجة']);

bool _isMelahLocation(String name) => _hasLocationTerm(name, ['ملح']);

bool _isTarhilLocation(String name) =>
    _hasLocationTerm(name, ['الترحيل', 'ترحيل', 'النرحييل']);

bool _isBeikaLocation(String name) => _hasLocationTerm(name, ['بيكة']);

bool _isAfarcoLocation(String name) =>
    _hasLocationTerm(name, ['افاركو', 'أفاركو']);

bool _isBmdLocation(String name) => _hasLocationTerm(name, ['bmd', 'بي ام دي']);

bool _isDarSalamaLocation(String name) =>
    _hasLocationTerm(name, ['دار السلامة', 'دارالسلامة']);

bool _isTwentyFourthLocation(String name) =>
    _hasLocationTerm(name, ['الرابع والعشرين']);

double? _specialDeliveryPrice(String pickup, String delivery) {
  final toujounineRules = <({bool Function(String) matcher, double price})>[
    (matcher: _isTwentyFourthLocation, price: _toujounineTwentyFourthPrice),
    (matcher: _isTensouelimLocation, price: _toujounineTensouelimPrice),
    (matcher: _isDarNaimLocation, price: _toujounineDarNaimPrice),
    (matcher: _isNaibLocation, price: _toujounineNaibPrice),
    (matcher: _isEtihadiaLocation, price: _toujounineEtihadiaPrice),
    (matcher: _isTeyaretLocation, price: _toujounineTeyaretPrice),
    (matcher: _isMadridLocation, price: _toujounineMadridPrice),
    (matcher: _isArafatLocation, price: _toujounineArafatPrice),
    (matcher: _isFalloujaLocation, price: _toujounineFalloujaPrice),
    (matcher: _isTarhilLocation, price: _toujounineTarhilPrice),
    (matcher: _isBeikaLocation, price: _toujounineBeikaPrice),
    (matcher: _isAfarcoLocation, price: _toujounineAfarcoPrice),
    (matcher: _isBmdLocation, price: _toujounineBmdPrice),
    (matcher: _isDarSalamaLocation, price: _toujounineDarSalamaPrice),
    (matcher: _isMelahLocation, price: _toujounineMelahPrice),
  ];
  for (final rule in toujounineRules) {
    if ((_isToujounineLocation(pickup) && rule.matcher(delivery)) ||
        (rule.matcher(pickup) && _isToujounineLocation(delivery))) {
      return rule.price;
    }
  }

  return null;
}

double? localDeliveryPriceFor(
  String pickup,
  String delivery,
  List<String> locations,
) {
  final pickupName = pickup.trim();
  final deliveryName = delivery.trim();
  final hasValidPoints =
      locations.contains(pickupName) &&
      locations.contains(deliveryName) &&
      pickupName != deliveryName;
  if (!hasValidPoints) return null;
  return _specialDeliveryPrice(pickupName, deliveryName) ?? 100;
}

Future<double?> fetchDeliveryPrice(String pickup, String delivery) async {
  try {
    final response = await ApiClient.instance.get(
      '/client/delivery-price',
      queryParameters: {'pickup': pickup.trim(), 'delivery': delivery.trim()},
    );
    final data = response.data;
    final price = data is Map ? data['price'] : null;
    if (price is num) return price.toDouble();
    if (price is String) return double.tryParse(price);
  } catch (_) {
    // The caller will fall back to the local default price.
  }
  return null;
}
