import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6)));
    _scale = Tween<double>(begin: 0.8, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final user = SupabaseService.currentUser;
    if (user == null) { context.go('/auth/login'); return; }
    final profile = await SupabaseService.getProfile(user.id);
    if (!mounted) return;
    switch (profile?.role) {
      case UserRole.admin:  context.go('/admin');
      case UserRole.seller: context.go('/seller');
      default:              context.go('/buyer');
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentSecondary],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(
                        color: AppColors.accent.withOpacity(0.35),
                        blurRadius: 40, spreadRadius: 0,
                      )],
                    ),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 46),
                  ),
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentSecondary],
                    ).createShader(b),
                    child: const Text('Veriqo', style: TextStyle(
                      fontSize: 40, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: -1,
                    )),
                  ),
                  const SizedBox(height: 8),
                  const Text('Verified Commerce', style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary,
                    letterSpacing: 2.5, fontWeight: FontWeight.w500,
                  )),
                  const SizedBox(height: 64),
                  SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.accent.withOpacity(0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
