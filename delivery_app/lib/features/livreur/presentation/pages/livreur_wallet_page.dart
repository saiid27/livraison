import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../providers/livreur_provider.dart';

class LivreurWalletPage extends ConsumerStatefulWidget {
  const LivreurWalletPage({super.key});

  @override
  ConsumerState<LivreurWalletPage> createState() => _LivreurWalletPageState();
}

class _LivreurWalletPageState extends ConsumerState<LivreurWalletPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(livreurProvider.notifier).loadWallet());
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final state = ref.watch(livreurProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'المحفظة' : 'Portefeuille'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/livreur'),
        ),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(livreurProvider.notifier).loadWallet(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Mon solde card ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'رصيدي' : 'Mon solde',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${state.balance.toStringAsFixed(2)} ${isAr ? 'أوقية' : 'MRU'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr ? 'عمولة المنصة: 9%' : 'Commission plateforme : 9%',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Recharger button ────────────────────────────────────
              ElevatedButton.icon(
                onPressed: () {
                  // Page de rechargement — à développer ultérieurement
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'صفحة شحن الرصيد ستُفعَّل قريبًا'
                            : 'Page de rechargement disponible prochainement',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_card_rounded),
                label: Text(
                  isAr ? 'شحن الرصيد' : 'Recharger le solde',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Info card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'يُخصَم 9% من قيمة كل توصيل كعمولة للمنصة عند قبولك للطلب. يجب أن يكون رصيدك كافياً قبل قبول أي طلب.'
                            : 'Une commission de 9% est déduite de chaque livraison lors de l\'acceptation. Votre solde doit être suffisant avant d\'accepter une commande.',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
