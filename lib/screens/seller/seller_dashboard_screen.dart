import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    final sellerAsync = ref.watch(currentSellerProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: sellerAsync.when(
        data: (seller) {
          if (seller == null) {
            return const EmptyState(
              icon: Icons.store_outlined,
              title: 'No seller profile',
              subtitle: 'Something went wrong loading your profile',
            );
          }

          final isPending = seller.verificationStatus == VerificationStatus.pending;
          final isRejected = seller.verificationStatus == VerificationStatus.rejected;
          final isVerified = seller.verificationStatus == VerificationStatus.approved;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.primary,
                expandedHeight: 140,
                floating: true,
                snap: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(seller.businessName,
                                      style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      )),
                                  Row(
                                    children: [
                                      StatusBadge.fromVerificationStatus(seller.verificationStatus),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Verification notice
              if (!isVerified)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _VerificationBanner(
                      isPending: isPending,
                      isRejected: isRejected,
                      reason: seller.rejectionReason,
                    ),
                  ),
                ),

              // Stats
              if (isVerified) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        _StatCard(
                          icon: Icons.inventory_2_outlined,
                          label: 'Products',
                          value: seller.totalProducts.toString(),
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.attach_money_rounded,
                          label: 'Total Sales',
                          value: '\$${seller.totalSales.toStringAsFixed(0)}',
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.star_outline_rounded,
                          label: 'Rating',
                          value: seller.rating.toStringAsFixed(1),
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Recent products
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: SectionHeader(
                    title: 'Recent Products',
                    action: 'View all',
                    onAction: () => context.go('/seller/products'),
                  ),
                ),
              ),

              Consumer(builder: (ctx, r, _) {
                final products = r.watch(sellerProductsProvider(seller.id));
                return products.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: EmptyState(
                            icon: Icons.add_box_outlined,
                            title: 'No products yet',
                            subtitle: 'Upload your first product',
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _SellerProductRow(product: items[i]),
                          childCount: items.take(5).length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(child: Text(e.toString())),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  final bool isPending, isRejected;
  final String? reason;
  const _VerificationBanner({required this.isPending, required this.isRejected, this.reason});

  @override
  Widget build(BuildContext context) {
    final color = isRejected ? AppColors.error : AppColors.warning;
    final icon = isRejected ? Icons.error_outline_rounded : Icons.hourglass_empty_rounded;
    final title = isRejected ? 'Verification rejected' : 'Verification pending';
    final msg = isRejected
        ? (reason ?? 'Your application was not approved. Please re-apply.')
        : 'Your seller application is under review. We\'ll notify you within 2-3 days.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
                const SizedBox(height: 4),
                Text(msg, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

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
            const SizedBox(height: 8),
            Text(value, style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: color,
            )),
            Text(label, style: const TextStyle(
              fontSize: 11, color: AppColors.textMuted,
            )),
          ],
        ),
      ),
    );
  }
}

class _SellerProductRow extends StatelessWidget {
  final Product product;
  const _SellerProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          StatusBadge.fromProductStatus(product.status),
        ],
      ),
    );
  }
}
