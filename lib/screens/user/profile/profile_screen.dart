import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(appUserProvider).asData?.value;
    final themeMode = ref.watch(themeModeProvider);
    final isDark    = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar
                Center(
                  child: Column(children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 40,
                            fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(user.name, style: context.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(user.role.toUpperCase(),
                          style: const TextStyle(fontSize: 11,
                              fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                // Info card
                _InfoCard(children: [
                  _Row(icon: Icons.store_rounded,   label: 'Shop',  value: user.shopName),
                  _Row(icon: Icons.person_rounded,  label: 'Owner', value: user.name),
                  _Row(icon: Icons.phone_rounded,   label: 'Phone', value: user.phone),
                  _Row(icon: Icons.email_rounded,   label: 'Email', value: user.email),
                ]),
                const SizedBox(height: 20),

                // Settings
                _InfoCard(children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark Mode'),
                    value: isDark,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    activeThumbColor: AppColors.primary,
                  ),
                ]),
                const SizedBox(height: 20),

                // Actions
                _InfoCard(children: [
                  _ActionTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    onTap: () async {
                      await ref.read(authNotifierProvider.notifier).sendReset(user.email);
                      if (context.mounted) {
                        context.showSnack('Reset link sent to ${user.email}');
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 12),
                _InfoCard(children: [
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: AppColors.error,
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(onPressed: () => context.pop(false),
                                child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => context.pop(true),
                              child: const Text('Sign Out',
                                  style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (context.mounted) context.go('/login');
                      }
                    },
                  ),
                ]),
              ],
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(children: children),
  );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: context.textTheme.bodySmall),
        Text(value.isEmpty ? '—' : value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ]),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _ActionTile({required this.icon, required this.label,
      required this.onTap, this.color = AppColors.textPrimary});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: color),
    title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );
}
