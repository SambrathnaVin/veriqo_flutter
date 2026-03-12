import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));
    final profile = ref.watch(profileProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('My Profile'),
      ),
      body: profile.when(
        data: (p) {
          if (p == null) return const Center(child: Text('Profile not found'));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Avatar section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, AppColors.accentSecondary],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (p.fullName?.isNotEmpty == true
                                  ? p.fullName![0].toUpperCase()
                                  : p.email[0].toUpperCase()),
                              style: const TextStyle(
                                fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surfaceBorder, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.fullName ?? 'No name',
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                      ),
                    ),
                    Text(p.email, style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary,
                    )),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: Text(
                        p.role.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.accent, letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Info section
              _SectionCard(
                title: 'Personal Information',
                children: [
                  _InfoRow(icon: Icons.person_outline_rounded, label: 'Full name', value: p.fullName ?? 'Not set'),
                  _InfoRow(icon: Icons.mail_outline_rounded, label: 'Email', value: p.email),
                  _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: p.phone ?? 'Not set'),
                ],
              ),
              const SizedBox(height: 16),

              // Account section
              _SectionCard(
                title: 'Account',
                children: [
                  _ActionRow(
                    icon: Icons.store_outlined,
                    label: 'Become a Seller',
                    onTap: () => context.push('/auth/seller-signup'),
                  ),
                  _ActionRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    onTap: () {},
                  ),
                  _ActionRow(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sign out
              GestureDetector(
                onTap: () async {
                  await SupabaseService.signOut();
                  if (context.mounted) context.go('/auth/login');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                      SizedBox(width: 12),
                      Text('Sign Out', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.error,
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textMuted, letterSpacing: 0.8,
        )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: List.generate(children.length * 2 - 1, (i) {
              if (i.isOdd) return const Divider(height: 1, color: AppColors.surfaceBorder);
              return children[i ~/ 2];
            }),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(value, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(
              fontSize: 14, color: AppColors.textPrimary,
            ))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
