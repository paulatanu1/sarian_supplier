import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _tabs = [
    '/admin/orders',
    '/admin/products',
    '/admin/users',
    '/admin/reports',
    '/admin/dashboard',
  ];
  static const _mainPath    = '/admin/orders';
  static const _exitTimeout = Duration(seconds: 2);

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  DateTime? _lastBackAt;

  Future<void> _handleBack() async {
    final router = GoRouter.of(context);
    final loc    = GoRouterState.of(context).matchedLocation;

    // Sub-route (e.g. /admin/orders/abc, /admin/products/123/edit) → pop.
    if (router.canPop()) {
      router.pop();
      return;
    }

    // On a tab other than main → switch to main tab.
    if (loc != AdminShell._mainPath) {
      router.go(AdminShell._mainPath);
      return;
    }

    // On main tab → double-back to exit.
    final now = DateTime.now();
    if (_lastBackAt == null ||
        now.difference(_lastBackAt!) > AdminShell._exitTimeout) {
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
    final loc = GoRouterState.of(context).matchedLocation;
    int idx = AdminShell._tabs.indexWhere((t) => loc.startsWith(t));
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
          onTap: (i) => context.go(AdminShell._tabs[i]),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }
}
