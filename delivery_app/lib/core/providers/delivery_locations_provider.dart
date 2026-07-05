import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/delivery_locations.dart';
import '../network/api_client.dart';

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
  return hasValidPoints ? 100 : null;
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
