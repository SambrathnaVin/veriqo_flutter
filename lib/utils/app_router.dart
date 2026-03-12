import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/shared/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/seller_signup_screen.dart';
import '../screens/buyer/main_shell.dart';
import '../screens/buyer/marketplace_screen.dart';
import '../screens/buyer/product_detail_screen.dart';
import '../screens/buyer/notifications_screen.dart';
import '../screens/buyer/profile_screen.dart';
import '../screens/buyer/cart_screen.dart';
import '../screens/buyer/scan_screen.dart';
import '../screens/seller/seller_shell.dart';
import '../screens/seller/seller_dashboard_screen.dart';
import '../screens/seller/seller_products_screen.dart';
import '../screens/seller/upload_product_screen.dart';
import '../screens/seller/edit_product_screen.dart';
import '../screens/seller/seller_notifications_screen.dart';
import '../screens/seller/seller_profile_screen.dart';
import '../screens/seller/seller_orders_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_products_screen.dart';
import '../screens/admin/admin_sellers_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_analytics_screen.dart';
import '../screens/admin/admin_notifications_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  // Watch profile so router rebuilds when role loads
  final profileAsync = ref.watch(currentProfileProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthLoading = authState.isLoading;
      if (isAuthLoading) return '/splash';

      final user = Supabase.instance.client.auth.currentUser;
      final isAuth = user != null;
      final onAuth = state.matchedLocation.startsWith('/auth');
      final onSplash = state.matchedLocation == '/splash';

      // Not logged in → send to login
      if (!isAuth && !onAuth && !onSplash) return '/auth/login';

      // Logged in on auth page → route by role
      if (isAuth && (onAuth || onSplash)) {
        // Wait for profile to load before routing
        if (profileAsync.isLoading) return '/splash';

        final profile = profileAsync.valueOrNull;
        if (profile == null) return '/auth/login';

        return _homeForRole(profile.role);
      }

      // Logged-in user on wrong section → redirect to their home
      if (isAuth && !onSplash && !onAuth) {
        if (profileAsync.isLoading) return null; // wait, don't redirect yet
        final profile = profileAsync.valueOrNull;
        if (profile == null) return null;

        final home = _homeForRole(profile.role);
        final onCorrectSection = state.matchedLocation.startsWith(
          home == '/admin' ? '/admin' : home == '/seller' ? '/seller' : '/buyer',
        );
        // Allow product detail for any role
        final onShared = state.matchedLocation.startsWith('/product');
        if (!onCorrectSection && !onShared) return home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth routes ───────────────────────────────────────
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/auth/seller-signup',
        builder: (_, __) => const SellerSignUpScreen(),
      ),

      // ── Buyer routes ──────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/buyer',
            builder: (_, __) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: '/buyer/scan',
            builder: (_, __) => const ScanScreen(),
          ),
          GoRoute(
            path: '/buyer/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/buyer/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/buyer/cart',
            builder: (_, __) => const CartScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),

      // ── Seller routes ─────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => SellerShell(child: child),
        routes: [
          GoRoute(
            path: '/seller',
            builder: (_, __) => const SellerDashboardScreen(),
          ),
          GoRoute(
            path: '/seller/products',
            builder: (_, __) => const SellerProductsScreen(),
          ),
          GoRoute(
            path: '/seller/upload',
            builder: (_, __) => const UploadProductScreen(),
          ),
          GoRoute(
            path: '/seller/edit/:id',
            builder: (_, state) =>
                EditProductScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/seller/orders',
            builder: (_, __) => const SellerOrdersScreen(),
          ),
          GoRoute(
            path: '/seller/notifications',
            builder: (_, __) => const SellerNotificationsScreen(),
          ),
          GoRoute(
            path: '/seller/profile',
            builder: (_, __) => const SellerProfileScreen(),
          ),
        ],
      ),

      // ── Admin routes ──────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (_, __) => const AdminProductsScreen(),
          ),
          GoRoute(
            path: '/admin/sellers',
            builder: (_, __) => const AdminSellersScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/analytics',
            builder: (_, __) => const AdminAnalyticsScreen(),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (_, __) => const AdminNotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});

String _homeForRole(UserRole role) {
  return switch (role) {
    UserRole.admin => '/admin',
    UserRole.seller => '/seller',
    UserRole.buyer => '/buyer',
  };
}
