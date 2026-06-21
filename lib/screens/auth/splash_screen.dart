import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..forward();
  late final Animation<double> _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  late final Animation<double> _scale = Tween(begin: 0.7, end: 1.0)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    ref.listen(appUserProvider, (_, next) {
      if (next.isLoading) return;
      final user = next.asData?.value;
      if (user == null)                          return context.go('/login');
      if (user.isAdmin)                          return context.go('/admin');
      if (!user.profileCompleted)                return context.go('/setup');
      context.go('/home');
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                  ),
                  child: const Icon(Icons.local_pharmacy_rounded,
                      size: 52, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                const Text('Sarian Healthcare',
                    style: TextStyle(color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                const Text('Supplier Portal',
                    style: TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 56),
                const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
