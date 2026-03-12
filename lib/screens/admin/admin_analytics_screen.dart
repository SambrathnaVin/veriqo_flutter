import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.primary,
            floating: true,
            snap: true,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentSecondary]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Platform performance overview', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          analyticsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
            ),
            data: (data) => SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // KPI grid
                  _SectionHeader('Key Metrics'),
                  const SizedBox(height: AppSpacing.md),
                  _KpiGrid(data: data),
                  const SizedBox(height: AppSpacing.xl),

                  // Seller funnel
                  _SectionHeader('Seller Verification Funnel'),
                  const SizedBox(height: AppSpacing.md),
                  _FunnelCard(data: data),
                  const SizedBox(height: AppSpacing.xl),

                  // Product status breakdown
                  _SectionHeader('Product Status Breakdown'),
                  const SizedBox(height: AppSpacing.md),
                  _ProductStatusCard(data: data),
                  const SizedBox(height: AppSpacing.xl),

                  // Top sellers
                  _SectionHeader('Top Sellers by Products'),
                  const SizedBox(height: AppSpacing.md),
                  _TopSellersCard(sellers: data.topSellers),
                  const SizedBox(height: AppSpacing.xl),

                  // Category distribution
                  _SectionHeader('Products by Category'),
                  const SizedBox(height: AppSpacing.md),
                  _CategoryCard(categories: data.categoryBreakdown),
                  const SizedBox(height: AppSpacing.xl),

                  // Recent activity
                  _SectionHeader('Recent Activity'),
                  const SizedBox(height: AppSpacing.md),
                  _RecentActivityCard(activity: data.recentActivity),
                  const SizedBox(height: AppSpacing.xl),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

// ── KPI Grid ───────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final AdminAnalytics data;
  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = [
      (label: 'Total Users', value: data.totalUsers.toString(), icon: Icons.people_rounded, color: AppColors.accent),
      (label: 'Active Sellers', value: data.activeSellers.toString(), icon: Icons.storefront_rounded, color: AppColors.success),
      (label: 'Total Products', value: data.totalProducts.toString(), icon: Icons.inventory_2_rounded, color: AppColors.accentSecondary),
      (label: 'Pending Reviews', value: data.pendingReviews.toString(), icon: Icons.pending_actions_rounded, color: AppColors.warning),
      (label: 'Approved Products', value: data.approvedProducts.toString(), icon: Icons.check_circle_rounded, color: AppColors.success),
      (label: 'Rejected Products', value: data.rejectedProducts.toString(), icon: Icons.cancel_rounded, color: AppColors.error),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.4,
      children: items.map((item) => _KpiTile(
        label: item.label,
        value: item.value,
        icon: item.icon,
        color: item.color,
      )).toList(),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      );
}

// ── Funnel Card ────────────────────────────────────────────────
class _FunnelCard extends StatelessWidget {
  final AdminAnalytics data;
  const _FunnelCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.totalSellerApplications;
    final stages = [
      (label: 'Applications', value: total, color: AppColors.accent),
      (label: 'Pending', value: data.pendingSellers, color: AppColors.warning),
      (label: 'Approved', value: data.approvedSellers, color: AppColors.success),
      (label: 'Rejected', value: data.rejectedSellers, color: AppColors.error),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: stages.map((s) {
          final pct = total == 0 ? 0.0 : s.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text('${s.value}  (${(pct * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(color: s.color, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceBorder,
                    valueColor: AlwaysStoppedAnimation(s.color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Product Status Card ────────────────────────────────────────
class _ProductStatusCard extends StatelessWidget {
  final AdminAnalytics data;
  const _ProductStatusCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.totalProducts == 0 ? 1 : data.totalProducts;
    final statuses = [
      (label: 'Approved', value: data.approvedProducts, color: AppColors.success),
      (label: 'Pending Review', value: data.pendingReviews, color: AppColors.warning),
      (label: 'Rejected', value: data.rejectedProducts, color: AppColors.error),
      (label: 'Draft', value: data.draftProducts, color: AppColors.textMuted),
      (label: 'Suspended', value: data.suspendedProducts, color: AppColors.accentSecondary),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: statuses.map((s) {
                  final flex = ((s.value / total) * 1000).round();
                  return flex == 0 ? const SizedBox() : Expanded(
                    flex: flex,
                    child: Container(color: s.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: statuses.map((s) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${s.label} (${s.value})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Top Sellers ────────────────────────────────────────────────
class _TopSellersCard extends StatelessWidget {
  final List<TopSellerStat> sellers;
  const _TopSellersCard({required this.sellers});

  @override
  Widget build(BuildContext context) {
    if (sellers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Center(child: Text('No sellers yet', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    final maxProducts = sellers.fold(0, (m, s) => s.productCount > m ? s.productCount : m);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: sellers.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final pct = maxProducts == 0 ? 0.0 : s.productCount / maxProducts;
          final isLast = i == sellers.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: i == 0 ? AppColors.warning.withOpacity(0.2)
                            : i == 1 ? AppColors.textMuted.withOpacity(0.2)
                            : AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: i == 0 ? AppColors.warning : i == 1 ? AppColors.textSecondary : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.businessName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: AppColors.surfaceBorder,
                              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${s.productCount}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 15)),
                        const Text('products', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(color: AppColors.surfaceBorder, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Category Card ──────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final List<CategoryStat> categories;
  const _CategoryCard({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Center(child: Text('No products yet', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    final maxCount = categories.fold(0, (m, c) => c.count > m ? c.count : m);
    final colors = [
      AppColors.accent, AppColors.accentSecondary, AppColors.success,
      AppColors.warning, AppColors.info, AppColors.error,
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: categories.asMap().entries.map((e) {
          final color = colors[e.key % colors.length];
          final pct = maxCount == 0 ? 0.0 : e.value.count / maxCount;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(e.value.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceBorder,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text('${e.value.count}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.right),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Recent Activity ────────────────────────────────────────────
class _RecentActivityCard extends StatelessWidget {
  final List<ActivityItem> activity;
  const _RecentActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Center(child: Text('No recent activity', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: activity.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == activity.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(item.subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(item.createdAt),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(color: AppColors.surfaceBorder, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}