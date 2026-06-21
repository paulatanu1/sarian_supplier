import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/products/screens/products_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/suppliers/screens/suppliers_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = auth.isLoading;
      if (isLoading) return '/';

      final isLoggedIn = auth.asData?.value != null;
      final onAuth = state.matchedLocation == '/login';

      if (!isLoggedIn && !onAuth) return '/login';
      if (isLoggedIn && onAuth) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (ctx, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (ctx, _) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (ctx, _) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (ctx, _) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (ctx, _) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/suppliers',
        builder: (ctx, _) => const SuppliersScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (ctx, _) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
