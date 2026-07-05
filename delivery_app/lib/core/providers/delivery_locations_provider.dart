import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/delivery_locations.dart';
import '../network/api_client.dart';

const _toujounineTensouelimPrice = 120.0;
const _toujounineDarNaimPrice = 130.0;

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

double? _specialDeliveryPrice(String pickup, String delivery) {
  final toujounineToTensouelim =
      _isToujounineLocation(pickup) && _isTensouelimLocation(delivery);
  final tensouelimToToujounine =
      _isTensouelimLocation(pickup) && _isToujounineLocation(delivery);
  if (toujounineToTensouelim || tensouelimToToujounine) {
    return _toujounineTensouelimPrice;
  }

  final toujounineToDarNaim =
      _isToujounineLocation(pickup) && _isDarNaimLocation(delivery);
  final darNaimToToujounine =
      _isDarNaimLocation(pickup) && _isToujounineLocation(delivery);
  if (toujounineToDarNaim || darNaimToToujounine) {
    return _toujounineDarNaimPrice;
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
