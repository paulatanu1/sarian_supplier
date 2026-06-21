import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/auth_provider.dart';

class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});
  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _form      = GlobalKey<FormState>();
  final _shopCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _shopCtrl.dispose(); _nameCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).adminCreateUser(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
        name:     _nameCtrl.text.trim(),
        shopName: _shopCtrl.text.trim(),
        phone:    _phoneCtrl.text.trim(),
      );
      if (mounted) {
        context.showSnack('User created successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create User')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.info),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A Firebase account will be created automatically. '
                  'Share the credentials with the store owner.',
                  style: context.textTheme.bodySmall,
                ),
              ),
            ]),
          ),

          _Field(_shopCtrl,  'Medicine Shop Name', Icons.storefront_outlined,
              required: true, cap: TextCapitalization.words),
          _Field(_nameCtrl,  'Owner Name',         Icons.person_outline,
              required: true, cap: TextCapitalization.words),
          _Field(_phoneCtrl, 'Mobile Number',      Icons.phone_outlined,
              required: true, type: TextInputType.phone, maxLen: 10,
              validator: (v) => v!.trim().isValidPhone ? null : 'Enter valid 10-digit number'),
          _Field(_emailCtrl, 'Email Address',      Icons.email_outlined,
              required: true, type: TextInputType.emailAddress,
              validator: (v) => v!.isValidEmail ? null : 'Enter valid email'),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => v!.isValidPassword ? null : 'Min 6 characters',
            ),
          ),

          ElevatedButton.icon(
            onPressed: _loading ? null : _create,
            icon: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.person_add_rounded),
            label: Text(_loading ? 'Creating…' : 'Create User'),
          ),
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool required;
  final TextInputType type;
  final TextCapitalization cap;
  final int? maxLen;
  final String? Function(String?)? validator;

  const _Field(this.ctrl, this.label, this.icon, {
    this.required = false,
    this.type     = TextInputType.text,
    this.cap      = TextCapitalization.none,
    this.maxLen,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: cap,
      maxLength: maxLen,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        counterText: '',
      ),
      validator: validator ?? (required
          ? (v) => v!.trim().isEmpty ? 'Required' : null
          : null),
    ),
  );
}
