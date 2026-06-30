import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('fr'));

final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode == 'ar' ? ArStrings() : FrStrings();
});
