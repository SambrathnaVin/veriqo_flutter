import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

final _productStatusFilterProvider = StateProvider<ProductStatus?>((ref) => null);

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_productStatusFilterProvider);
    final products = ref.watch(adminProductsProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Product Review'),
      ),
      body: Column(
        children: [
          // Filter tabs
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter == null,
                  onTap: () =>
                      ref.read(_productStatusFilterProvider.notifier).state = null,
                ),
                _FilterChip(
                  label: 'Pending',
                  selected: filter == ProductStatus.pendingReview,
                  color: AppColors.pending,
                  onTap: () => ref.read(_productStatusFilterProvider.notifier).state =
                      ProductStatus.pendingReview,
                ),
                _FilterChip(
                  label: 'Approved',
                  selected: filter == ProductStatus.approved,
                  color: AppColors.approved,
                  onTap: () => ref.read(_productStatusFilterProvider.notifier).state =
                      ProductStatus.approved,
                ),
                _FilterChip(
                  label: 'Rejected',
                  selected: filter == ProductStatus.rejected,
                  color: AppColors.rejected,
                  onTap: () => ref.read(_productStatusFilterProvider.notifier).state =
                      ProductStatus.rejected,
                ),
              ],
            ),
          ),

          Expanded(
            child: products.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products found',
                    subtitle: 'Nothing matches this filter',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _ProductReviewCard(
                    product: items[i],
                    onRefresh: () => ref.refresh(adminProductsProvider(filter)),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to load',
                  subtitle: e.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.refresh(adminProductsProvider(filter)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Product Review Card ───────────────────────────────────────
class _ProductReviewCard extends StatefulWidget {
  final Product product;
  final VoidCallback onRefresh;

  const _ProductReviewCard({required this.product, required this.onRefresh});

  @override
  State<_ProductReviewCard> createState() => _ProductReviewCardState();
}

class _ProductReviewCardState extends State<_ProductReviewCard> {
  bool _loading = false;
  bool _expanded = false;

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.updateProductStatus(
          widget.product.id, ProductStatus.approved);
      if (mounted) {
        showSnack(context, 'Product approved and is now live');
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final reason = await _showRejectDialog(context);
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.updateProductStatus(
          widget.product.id, ProductStatus.rejected,
          reason: reason.trim());
      if (mounted) {
        showSnack(context, 'Product rejected');
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _showRejectDialog(BuildContext ctx) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rejection Reason',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Explain why this product is rejected...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isPending = p.status == ProductStatus.pendingReview;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isPending
              ? AppColors.pending.withOpacity(0.3)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: p.primaryImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: p.primaryImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppColors.surfaceElevated),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceElevated,
                              child: const Icon(Icons.image_outlined,
                                  color: AppColors.textMuted),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceElevated,
                            child: const Icon(Icons.inventory_2_outlined,
                                color: AppColors.textMuted),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${p.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (p.seller != null)
                        Row(
                          children: [
                            const Icon(Icons.store_outlined,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                p.seller!.businessName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge.fromProductStatus(p.status),
              ],
            ),
          ),

          // Expand details button
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Text('View details',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted)),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (_expanded) ...[
            const SizedBox(height: 10),
            const Divider(
                height: 1,
                color: AppColors.surfaceBorder,
                indent: 14,
                endIndent: 14),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.description != null && p.description!.isNotEmpty) ...[
                    const Text('Description',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(p.description!,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4)),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _DetailItem(
                          label: 'Stock', value: '${p.stockQuantity}'),
                      if (p.category != null)
                        _DetailItem(
                            label: 'Category',
                            value: p.category!.name),
                      if (p.originCountry != null)
                        _DetailItem(
                            label: 'Origin',
                            value: p.originCountry!),
                      if (p.manufacturer != null)
                        _DetailItem(
                            label: 'Manufacturer',
                            value: p.manufacturer!),
                      if (p.sku != null)
                        _DetailItem(label: 'SKU', value: p.sku!),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Action buttons (only for pending)
          if (isPending) ...[
            const Divider(height: 1, color: AppColors.surfaceBorder),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _reject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(
                              color: AppColors.error, width: 1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _approve,
                        icon: _loading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary))
                            : const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Show rejection reason
          if (p.status == ProductStatus.rejected &&
              p.rejectionReason != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.error, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.rejectionReason!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.error, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label, value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
