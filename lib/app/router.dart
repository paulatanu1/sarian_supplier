import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/user/user_shell.dart';
import '../screens/user/home/home_screen.dart';
import '../screens/user/products/products_screen.dart';
import '../screens/user/products/product_detail_screen.dart';
import '../screens/user/cart/cart_screen.dart';
import '../screens/user/orders/orders_screen.dart';
import '../screens/user/orders/order_detail_screen.dart';
import '../screens/user/reports/reports_screen.dart';
import '../screens/user/profile/profile_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/dashboard/admin_dashboard_screen.dart';
import '../screens/admin/products/admin_products_screen.dart';
import '../screens/admin/products/add_edit_product_screen.dart';
import '../screens/admin/orders/admin_orders_screen.dart';
import '../screens/admin/orders/admin_order_detail_screen.dart';
import '../screens/admin/users/admin_users_screen.dart';
import '../screens/admin/users/create_user_screen.dart';
import '../screens/admin/reports/admin_reports_screen.dart';

final _userShellKey  = GlobalKey<NavigatorState>(debugLabel: 'user-shell');
final _adminShellKey = GlobalKey<NavigatorState>(debugLabel: 'admin-shell');

final routerProvider = Provider<GoRouter>((ref) {
  // Stable router instance — refresh it when auth state changes
  final router = GoRouter(
    initialLocation: '/',
    redirect: (ctx, state) {
      final authAsync = ref.read(appUserProvider);

      // Auth still loading → stay on splash
      if (authAsync.isLoading) return null;

      final user    = authAsync.asData?.value;
      final loggedIn = user != null;
      final loc      = state.matchedLocation;
      final onPublic = loc == '/' || loc == '/login';

      if (!loggedIn) return onPublic ? '/login' : '/login';

      if (user.isAdmin) {
        if (loc.startsWith('/admin')) return null;
        return '/admin/orders';
      }

      if (!user.profileCompleted) {
        return loc == '/setup' ? null : '/setup';
      }

      if (onPublic || loc == '/setup') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/',      builder: (ctx, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (ctx, _) => const LoginScreen()),
      GoRoute(path: '/setup', builder: (ctx, _) => const ProfileSetupScreen()),

      // ── User shell ─────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _userShellKey,
        builder: (ctx, state, child) => UserShell(child: child),
        routes: [
          GoRoute(path: '/home',     builder: (ctx, _) => const HomeScreen()),
          GoRoute(
            path: '/products',
            builder: (ctx, _) => const ProductsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (ctx, s) =>
                    ProductDetailScreen(productId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/cart',     builder: (ctx, _) => const CartScreen()),
          GoRoute(
            path: '/orders',
            builder: (ctx, _) => const OrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (ctx, s) =>
                    OrderDetailScreen(orderId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/reports', builder: (ctx, _) => const ReportsScreen()),
          GoRoute(path: '/profile', builder: (ctx, _) => const ProfileScreen()),
        ],
      ),

      // ── Admin shell ────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (ctx, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            redirect: (ctx, _) => '/admin/orders',
          ),
          GoRoute(
            path: '/admin/dashboard',
            builder: (ctx, _) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (ctx, _) => const AdminProductsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (ctx, _) => const AddEditProductScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (ctx, s) =>
                    AddEditProductScreen(productId: s.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/orders',
            builder: (ctx, _) => const AdminOrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (ctx, s) =>
                    AdminOrderDetailScreen(orderId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/users',
            builder: (ctx, _) => const AdminUsersScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (ctx, _) => const CreateUserScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (ctx, _) => const AdminReportsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (ctx, s) => Scaffold(
      body: Center(child: Text('Page not found: ${s.error}')),
    ),
  );

  // Refresh router whenever auth state changes
  ref.listen(appUserProvider, (prev, next) => router.refresh());

  return router;
});
