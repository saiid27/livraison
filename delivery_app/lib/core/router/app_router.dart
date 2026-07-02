import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/captain_pending_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/public_info_page.dart';
import '../../features/auth/presentation/pages/account_deletion_request_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/client/presentation/pages/client_home_page.dart';
import '../../features/client/presentation/pages/client_orders_page.dart';
import '../../features/client/presentation/pages/client_new_order_page.dart';
import '../../features/client/presentation/pages/client_track_page.dart';
import '../../features/client/presentation/pages/client_profile_page.dart';
import '../../features/client/presentation/pages/client_order_search_page.dart';
import '../../features/livreur/presentation/pages/livreur_home_page.dart';
import '../../features/livreur/presentation/pages/livreur_history_page.dart';
import '../../features/livreur/presentation/pages/livreur_profile_page.dart';
import '../../features/livreur/presentation/pages/livreur_wallet_page.dart';
import '../../features/admin/presentation/pages/admin_home_page.dart';
import '../../features/admin/presentation/pages/admin_orders_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_approvals_page.dart';
import '../../features/admin/presentation/pages/admin_recharge_requests_page.dart';
import '../../features/admin/presentation/pages/admin_payment_methods_page.dart';
import '../../features/admin/presentation/pages/admin_account_deletion_requests_page.dart';
import '../../features/livreur/presentation/pages/livreur_recharge_page.dart';
import '../../features/merchant/presentation/pages/merchant_home_page.dart';
import '../constants/app_constants.dart';
import '../providers/language_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(
    authProvider.select((state) => state.isAuthenticated),
  );
  final role = ref.watch(authProvider.select((state) => state.role));
  final approvalStatus = ref.watch(
    authProvider.select((state) => state.approvalStatus),
  );

  return GoRouter(
    initialLocation: isAuthenticated
        ? _getHomeRoute(role, approvalStatus)
        : '/login',
    redirect: (context, state) {
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/about' ||
          state.matchedLocation == '/privacy' ||
          state.matchedLocation == '/contact' ||
          state.matchedLocation == '/delete-account' ||
          state.matchedLocation == '/splash';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) {
        return _getHomeRoute(role, approvalStatus);
      }
      if (isAuthenticated &&
          (role == AppConstants.roleLivreur ||
              role == AppConstants.roleCarCaptain)) {
        final isApproved = approvalStatus == 'approved';
        if (!isApproved && state.matchedLocation != '/captain-pending') {
          return '/captain-pending';
        }
        if (isApproved && state.matchedLocation == '/captain-pending') {
          return _getHomeRoute(role, approvalStatus);
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(
        path: '/about',
        builder: (context, state) =>
            const PublicInfoPage(type: PublicInfoType.about),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) =>
            const PublicInfoPage(type: PublicInfoType.privacy),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) =>
            const PublicInfoPage(type: PublicInfoType.contact),
      ),
      GoRoute(
        path: '/delete-account',
        builder: (context, state) => const AccountDeletionRequestPage(),
      ),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/captain-pending',
        builder: (_, __) => const CaptainPendingPage(),
      ),
      GoRoute(path: '/merchant', builder: (_, __) => const MerchantHomePage()),
      GoRoute(
        path: '/client/order-search/:orderId',
        builder: (_, state) =>
            ClientOrderSearchPage(orderId: state.pathParameters['orderId']!),
      ),

      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(path: '/client', builder: (_, __) => const ClientHomePage()),
          GoRoute(
            path: '/client/orders',
            builder: (_, __) => const ClientOrdersPage(),
          ),
          GoRoute(
            path: '/client/new-order',
            builder: (_, state) => ClientNewOrderPage(
              serviceType: state.uri.queryParameters['type'] == 'course'
                  ? 'course'
                  : 'delivery',
            ),
          ),
          GoRoute(
            path: '/client/track/:orderId',
            builder: (_, state) =>
                ClientTrackPage(orderId: state.pathParameters['orderId']!),
          ),
          GoRoute(
            path: '/client/profile',
            builder: (_, __) => const ClientProfilePage(),
          ),
        ],
      ),

      ShellRoute(
        builder: (context, state, child) => LivreurShell(child: child),
        routes: [
          GoRoute(
            path: '/livreur',
            builder: (_, __) => const LivreurHomePage(),
          ),
          GoRoute(
            path: '/livreur/profile',
            builder: (_, __) => const LivreurProfilePage(),
          ),
          GoRoute(
            path: '/livreur/wallet',
            builder: (_, __) => const LivreurWalletPage(),
          ),
          GoRoute(
            path: '/livreur/history',
            builder: (_, __) => const LivreurHistoryPage(),
          ),
          GoRoute(
            path: '/livreur/recharge',
            builder: (_, __) => const LivreurRechargePage(),
          ),
        ],
      ),

      ShellRoute(
        builder: (context, state, child) => LivreurShell(child: child),
        routes: [
          GoRoute(
            path: '/car-captain',
            builder: (_, __) => const LivreurHomePage(
              baseRoute: '/car-captain',
              serviceType: 'course',
              captainTitleAr: 'كابتن سيارة',
              captainTitleFr: 'Capitaine voiture',
              markerIcon: Icons.directions_car_rounded,
            ),
          ),
          GoRoute(
            path: '/car-captain/profile',
            builder: (_, __) => const LivreurProfilePage(
              baseRoute: '/car-captain',
              roleLabelAr: 'كابتن سيارة',
              roleLabelFr: 'Capitaine voiture',
            ),
          ),
          GoRoute(
            path: '/car-captain/wallet',
            builder: (_, __) =>
                const LivreurWalletPage(baseRoute: '/car-captain'),
          ),
          GoRoute(
            path: '/car-captain/history',
            builder: (_, __) =>
                const LivreurHistoryPage(baseRoute: '/car-captain'),
          ),
          GoRoute(
            path: '/car-captain/recharge',
            builder: (_, __) =>
                const LivreurRechargePage(baseRoute: '/car-captain'),
          ),
        ],
      ),

      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin', builder: (_, __) => const AdminHomePage()),
          GoRoute(
            path: '/admin/orders',
            builder: (_, __) => const AdminOrdersPage(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const AdminUsersPage(),
          ),
          GoRoute(
            path: '/admin/approvals',
            builder: (_, __) => const AdminApprovalsPage(),
          ),
          GoRoute(
            path: '/admin/recharge-requests',
            builder: (_, __) => const AdminRechargeRequestsPage(),
          ),
          GoRoute(
            path: '/admin/payment-methods',
            builder: (_, __) => const AdminPaymentMethodsPage(),
          ),
          GoRoute(
            path: '/admin/account-deletion-requests',
            builder: (_, __) => const AdminAccountDeletionRequestsPage(),
          ),
        ],
      ),
    ],
  );
});

String _getHomeRoute(String? role, String? approvalStatus) {
  switch (role) {
    case 'client':
      return '/client';
    case 'livreur':
      return approvalStatus == 'approved' ? '/livreur' : '/captain-pending';
    case 'car_captain':
      return approvalStatus == 'approved' ? '/car-captain' : '/captain-pending';
    case 'merchant':
      return '/merchant';
    case 'admin':
      return '/admin';
    default:
      return '/login';
  }
}

class ClientShell extends ConsumerWidget {
  final Widget child;
  const ClientShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final index = switch (location) {
      '/client' => 0,
      '/client/orders' => 1,
      '/client/new-order' => 2,
      '/client/profile' => 3,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/client');
              break;
            case 1:
              context.go('/client/orders');
              break;
            case 2:
              context.go('/client/new-order');
              break;
            case 3:
              context.go('/client/profile');
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: s.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_outlined),
            selectedIcon: const Icon(Icons.receipt),
            label: s.navOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: s.navNewOrder,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: s.navProfile,
          ),
        ],
      ),
    );
  }
}

class LivreurShell extends ConsumerWidget {
  final Widget child;
  const LivreurShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }
}

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final index = switch (location) {
      '/admin' => 0,
      '/admin/orders' => 1,
      '/admin/users' => 2,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/admin');
              break;
            case 1:
              context.go('/admin/orders');
              break;
            case 2:
              context.go('/admin/users');
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: s.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: s.navOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: s.usersLabel,
          ),
        ],
      ),
    );
  }
}
