import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      debugPrint('LOGIN: attempting sign in...');
      final res = await SupabaseService.signIn(_email.text.trim(), _password.text);
      debugPrint('LOGIN: signIn complete. user=${res.user?.id}');
      if (!mounted) return;
      if (res.user != null) {
        debugPrint('LOGIN: fetching profile...');
        Profile? profile;
        for (int i = 0; i < 3; i++) {
          profile = await SupabaseService.getProfile(res.user!.id);
          debugPrint('LOGIN: attempt $i profile=$profile role=${profile?.role}');
          if (profile != null) break;
          await Future.delayed(const Duration(milliseconds: 500));
        }
        if (!mounted) return;
        debugPrint('LOGIN: navigating based on role=${profile?.role}');
        switch (profile?.role) {
          case UserRole.admin:
            debugPrint('LOGIN: going to /admin');
            context.go('/admin');
          case UserRole.seller:
            debugPrint('LOGIN: going to /seller');
            context.go('/seller');
          default:
            debugPrint('LOGIN: going to /buyer');
            context.go('/buyer');
        }
      } else {
        debugPrint('LOGIN: res.user is null!');
        if (mounted) showSnack(context, 'Login failed — no user returned', error: true);
      }
    } catch (e, stack) {
      debugPrint('LOGIN ERROR: $e');
      debugPrint('LOGIN STACK: $stack');
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentSecondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Veriqo', style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
                  ],
                ),
                const SizedBox(height: 48),
                const Text('Welcome back', style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.5,
                )),
                const SizedBox(height: 8),
                const Text('Sign in to your account', style: TextStyle(
                  fontSize: 15, color: AppColors.textSecondary,
                )),
                const SizedBox(height: 40),

                VTextField(
                  controller: _email,
                  label: 'Email address',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                VTextField(
                  controller: _password,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textMuted, size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                VButton(
                  label: 'Sign In',
                  onPressed: _login,
                  isLoading: _loading,
                  icon: Icons.arrow_forward_rounded,
                ),
                const SizedBox(height: 24),

                // Divider
                Row(children: [
                  const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                  const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                ]),
                const SizedBox(height: 24),

                // Sign up options
                Row(children: [
                  Expanded(
                    child: _AuthOptionCard(
                      icon: Icons.person_outline_rounded,
                      label: 'Buyer',
                      subtitle: 'Shop products',
                      onTap: () => context.go('/auth/signup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AuthOptionCard(
                      icon: Icons.store_outlined,
                      label: 'Seller',
                      subtitle: 'Sell products',
                      onTap: () => context.go('/auth/seller-signup'),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Don\'t have an account? Choose a role above',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _AuthOptionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary,
            )),
            Text(subtitle, style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}