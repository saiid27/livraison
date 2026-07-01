import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

class LanguageButton extends ConsumerWidget {
  final Color color;
  const LanguageButton({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';
    final nextLanguage = isAr ? 'Français' : 'العربية';

    return Semantics(
      button: true,
      label: nextLanguage,
      child: Tooltip(
        message: nextLanguage,
        child: Material(
          color: color.withValues(alpha: 0.09),
          shape: StadiumBorder(
            side: BorderSide(color: color.withValues(alpha: 0.22)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              ref.read(localeProvider.notifier).state = isAr
                  ? const Locale('fr')
                  : const Locale('ar');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nextLanguage,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.language_rounded, size: 24, color: color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
