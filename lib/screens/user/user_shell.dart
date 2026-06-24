import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cart_provider.dart';

class UserShell extends ConsumerStatefulWidget {
  final Widget child;
  const UserShell({super.key, required this.child});

  static const _tabs = [
    '/home', '/products', '/cart', '/orders', '/profile',
  ];
  static const _mainPath    = '/home';
  static const _exitTimeout = Duration(seconds: 2);

  @override
  ConsumerState<UserShell> createState() => _UserShellState();
}

class _UserShellState extends ConsumerState<UserShell> {
  DateTime? _lastBackAt;

  Future<void> _handleBack() async {
    final router = GoRouter.of(context);
    final loc    = GoRouterState.of(context).matchedLocation;

    // Sub-route (e.g. /products/abc, /orders/xyz) → pop normally.
    if (router.canPop()) {
      router.pop();
      return;
    }

    // On a tab other than Home → switch to Home.
    if (loc != UserShell._mainPath) {
      router.go(UserShell._mainPath);
      return;
    }

    // On Home → double-back to exit.
    final now = DateTime.now();
    if (_lastBackAt == null ||
        now.difference(_lastBackAt!) > UserShell._exitTimeout) {
      _lastBackAt = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);
    final loc = GoRouterState.of(context).matchedLocation;
    int idx = UserShell._tabs.indexWhere((t) => loc.startsWith(t));
    if (idx < 0) idx = 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) => context.go(UserShell._tabs[i]),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: badges.Badge(
                showBadge: cartCount > 0,
                badgeContent: Text('$cartCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9)),
                badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.accent),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: badges.Badge(
                showBadge: cartCount > 0,
                badgeContent: Text('$cartCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9)),
                badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.accent),
                child: const Icon(Icons.shopping_cart_rounded),
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
