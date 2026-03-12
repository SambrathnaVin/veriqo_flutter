import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('All Users'),
      ),
      body: users.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No users yet',
            );
          }

          // Group by role
          final buyers =
              list.where((u) => u.role == UserRole.buyer).toList();
          final sellers =
              list.where((u) => u.role == UserRole.seller).toList();
          final admins =
              list.where((u) => u.role == UserRole.admin).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Summary cards
              Row(
                children: [
                  _SummaryCard(
                    icon: Icons.people_outline_rounded,
                    label: 'Buyers',
                    count: buyers.length,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  _SummaryCard(
                    icon: Icons.store_outlined,
                    label: 'Sellers',
                    count: sellers.length,
                    color: AppColors.accentSecondary,
                  ),
                  const SizedBox(width: 10),
                  _SummaryCard(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admins',
                    count: admins.length,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (admins.isNotEmpty) ...[
                _SectionLabel(label: 'Admins', count: admins.length),
                const SizedBox(height: 8),
                ...admins.map((u) => _UserCard(user: u)),
                const SizedBox(height: 20),
              ],

              if (sellers.isNotEmpty) ...[
                _SectionLabel(label: 'Sellers', count: sellers.length),
                const SizedBox(height: 8),
                ...sellers.map((u) => _UserCard(user: u)),
                const SizedBox(height: 20),
              ],

              if (buyers.isNotEmpty) ...[
                _SectionLabel(label: 'Buyers', count: buyers.length),
                const SizedBox(height: 8),
                ...buyers.map((u) => _UserCard(user: u)),
              ],

              const SizedBox(height: 60),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load users',
            subtitle: e.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.refresh(allUsersProvider),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final Profile user;
  const _UserCard({required this.user});

  Color get _roleColor => switch (user.role) {
        UserRole.admin => AppColors.warning,
        UserRole.seller => AppColors.accentSecondary,
        UserRole.buyer => AppColors.accent,
      };

  IconData get _roleIcon => switch (user.role) {
        UserRole.admin => Icons.admin_panel_settings_outlined,
        UserRole.seller => Icons.store_outlined,
        UserRole.buyer => Icons.person_outline_rounded,
      };

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final initials = (user.fullName?.isNotEmpty == true
            ? user.fullName![0]
            : user.email[0])
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _roleColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _roleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName?.isNotEmpty == true
                      ? user.fullName!
                      : 'No name',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Right side: role badge + date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _roleColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_roleIcon, size: 11, color: _roleColor),
                    const SizedBox(width: 4),
                    Text(
                      user.role.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _roleColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Joined ${_formatDate(user.createdAt)}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
