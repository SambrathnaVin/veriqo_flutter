import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));
    final seller = ref.watch(currentSellerProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(backgroundColor: AppColors.primary, title: const Text('Seller Profile')),
      body: seller.when(
        data: (s) {
          if (s == null) return const Center(child: Text('No seller profile'));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Business card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.surfaceCard, AppColors.surfaceElevated],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentSecondary]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.store_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.businessName, style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                              )),
                              StatusBadge.fromVerificationStatus(s.verificationStatus),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (s.businessDescription != null) ...[
                      const SizedBox(height: 14),
                      Text(s.businessDescription!, style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary, height: 1.5,
                      )),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Chip(icon: Icons.inventory_2_outlined, label: '${s.totalProducts} products'),
                        const SizedBox(width: 10),
                        _Chip(icon: Icons.star_outline_rounded, label: s.rating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _SectionCard(title: 'Business Details', children: [
                _InfoRow(icon: Icons.store_outlined, label: 'Business name', value: s.businessName),
                if (s.businessAddress != null)
                  _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: s.businessAddress!),
                _InfoRow(icon: Icons.badge_outlined, label: 'National ID', value: '${s.nationalIdNumber.substring(0, 4)}****'),
              ]),
              const SizedBox(height: 16),

              _SectionCard(title: 'Account', children: [
                _ActionRow(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}),
                _ActionRow(icon: Icons.storefront_outlined, label: 'View store in marketplace', onTap: () => context.go('/buyer')),
              ]),
              const SizedBox(height: 16),

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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
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
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
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
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
