import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/language_button.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 650);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeIn),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(_splashDuration);
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      final route = switch (auth.role) {
        AppConstants.roleClient => '/client',
        AppConstants.roleLivreur =>
          auth.approvalStatus == 'approved' ? '/livreur' : '/captain-pending',
        AppConstants.roleCarCaptain =>
          auth.approvalStatus == 'approved'
              ? '/car-captain'
              : '/captain-pending',
        AppConstants.roleMerchant => '/merchant',
        AppConstants.roleAdmin => '/admin',
        _ => '/login',
      };
      context.go(route);
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/delivery_scooter_mark.svg',
                            width: 68,
                            height: 68,
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      const Text(
                        'mayahsar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'توصيل سريع وموثوق',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 72),
                      const SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(top: 54, right: 14, child: LanguageButton()),
        ],
      ),
    );
  }
}
