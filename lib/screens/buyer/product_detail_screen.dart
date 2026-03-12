import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _imageIndex = 0;
  bool _addingCart = false;

  Future<void> _addToCart() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      showSnack(context, 'Please sign in to add to cart', error: true);
      return;
    }
    setState(() => _addingCart = true);
    try {
      await SupabaseService.addToCart(user.id, widget.productId, 1);
      if (mounted) showSnack(context, 'Added to cart');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _addingCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: product.when(
        data: (p) {
          if (p == null) {
            return const Center(
              child: EmptyState(icon: Icons.inventory_2_outlined, title: 'Product not found'),
            );
          }
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Images
                  SliverAppBar(
                    backgroundColor: AppColors.surfaceCard,
                    expandedHeight: 340,
                    pinned: true,
                    leading: IconButton(
                      icon: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border_rounded, size: 18),
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: p.images.isEmpty
                          ? Container(
                              color: AppColors.surfaceCard,
                              child: const Icon(Icons.image_outlined,
                                  color: AppColors.textMuted, size: 64),
                            )
                          : PageView.builder(
                              itemCount: p.images.length,
                              onPageChanged: (i) => setState(() => _imageIndex = i),
                              itemBuilder: (_, i) => CachedNetworkImage(
                                imageUrl: p.images[i].url,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),

                  // Image dots
                  if (p.images.length > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(p.images.length, (i) => Container(
                            width: i == _imageIndex ? 20 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == _imageIndex ? AppColors.accent : AppColors.surfaceBorder,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                        ),
                      ),
                    ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category
                          if (p.category != null) ...[
                            Text(p.category!.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11, letterSpacing: 1.5,
                                  color: AppColors.accent, fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 8),
                          ],

                          // Name
                          Text(p.name, style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary, height: 1.3,
                          )),
                          const SizedBox(height: 16),

                          // Price row
                          Row(
                            children: [
                              Text('\$${p.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w800,
                                    color: AppColors.accent,
                                  )),
                              if (p.comparePrice != null) ...[
                                const SizedBox(width: 12),
                                Text('\$${p.comparePrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16, color: AppColors.textMuted,
                                      decoration: TextDecoration.lineThrough,
                                    )),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  label: '-${p.discountPercent.toStringAsFixed(0)}%',
                                  color: AppColors.error,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Rating & Stock
                          Row(
                            children: [
                              if (p.rating > 0) ...[
                                const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                                const SizedBox(width: 4),
                                Text('${p.rating.toStringAsFixed(1)} (${p.reviewsCount})',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                const SizedBox(width: 16),
                              ],
                              Icon(
                                p.stockQuantity > 0 ? Icons.inventory_2_outlined : Icons.remove_circle_outline,
                                color: p.stockQuantity > 0 ? AppColors.success : AppColors.error,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                p.stockQuantity > 0 ? '${p.stockQuantity} in stock' : 'Out of stock',
                                style: TextStyle(
                                  color: p.stockQuantity > 0 ? AppColors.success : AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: AppColors.surfaceBorder),
                          const SizedBox(height: 16),

                          // Description
                          if (p.description != null) ...[
                            const Text('Description', style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                            )),
                            const SizedBox(height: 8),
                            Text(p.description!, style: const TextStyle(
                              fontSize: 14, color: AppColors.textSecondary, height: 1.6,
                            )),
                            const SizedBox(height: 24),
                          ],

                          // Origin info
                          if (p.originCountry != null || p.manufacturer != null) ...[
                            const Text('Product Details', style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                            )),
                            const SizedBox(height: 12),
                            if (p.originCountry != null)
                              _DetailRow(label: 'Origin', value: p.originCountry!),
                            if (p.manufacturer != null)
                              _DetailRow(label: 'Manufacturer', value: p.manufacturer!),
                            if (p.sku != null)
                              _DetailRow(label: 'SKU', value: p.sku!),
                            const SizedBox(height: 24),
                          ],

                          // Seller info
                          if (p.seller != null) ...[
                            const Divider(color: AppColors.surfaceBorder),
                            const SizedBox(height: 16),
                            const Text('Sold by', style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                            )),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.store_outlined, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(p.seller!.businessName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600, fontSize: 15,
                                                  color: AppColors.textPrimary,
                                                )),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.verified_rounded,
                                                color: AppColors.accent, size: 15),
                                          ],
                                        ),
                                        Text('${p.seller!.totalProducts} products',
                                            style: const TextStyle(
                                              fontSize: 12, color: AppColors.textSecondary,
                                            )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 120),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom buy bar
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: const Border(top: BorderSide(color: AppColors.surfaceBorder)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.8),
                        blurRadius: 20, offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: const Icon(Icons.favorite_border_rounded,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: p.stockQuantity > 0 ? _addToCart : null,
                            icon: _addingCart
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.primary),
                                  )
                                : const Icon(Icons.shopping_bag_rounded, size: 18),
                            label: Text(p.stockQuantity > 0 ? 'Add to Cart' : 'Out of Stock'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
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

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(
              fontSize: 13, color: AppColors.textMuted,
            )),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(
              fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500,
            )),
          ),
        ],
      ),
    );
  }
}
