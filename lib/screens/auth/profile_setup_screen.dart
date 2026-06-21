import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _form     = GlobalKey<FormState>();
  final _shopCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _shopCtrl.dispose(); _nameCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).completeProfile(
      name:     _nameCtrl.text.trim(),
      shopName: _shopCtrl.text.trim(),
      phone:    _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    final err = ref.read(authNotifierProvider).error;
    if (err != null) {
      context.showSnack(err.toString(), isError: true);
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.store_rounded, color: AppColors.primary, size: 32),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Complete Your Profile', style: context.textTheme.titleLarge),
                    Text('Required for placing orders', style: context.textTheme.bodyMedium),
                  ])),
                ]),
              ),
              const SizedBox(height: 36),

              _label('Medicine Shop Name'),
              TextFormField(
                controller: _shopCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Sharma Medical Store',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (v) => v!.trim().length < 3 ? 'Enter shop name (min 3 chars)' : null,
              ),
              const SizedBox(height: 20),

              _label('Owner Name'),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Ramesh Sharma',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => v!.trim().length < 2 ? 'Enter owner name' : null,
              ),
              const SizedBox(height: 20),

              _label('Mobile Number'),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  hintText: '10-digit mobile number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  prefixText: '+91  ',
                  counterText: '',
                ),
                validator: (v) => v!.trim().isValidPhone ? null : 'Enter valid 10-digit number',
              ),
              const SizedBox(height: 36),

              ElevatedButton.icon(
                onPressed: loading ? null : _save,
                icon: loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_rounded),
                label: Text(loading ? 'Saving…' : 'Save & Continue'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
  );
}
