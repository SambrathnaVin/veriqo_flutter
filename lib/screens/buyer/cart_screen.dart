import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));
    final cart = ref.watch(cartProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('My Cart'),
        actions: [
          cart.when(
            data: (items) => items.isNotEmpty
                ? TextButton(
                    onPressed: () async {
                      await SupabaseService.clearCart(user.id);
                      ref.refresh(cartProvider(user.id));
                    },
                    child: const Text('Clear', style: TextStyle(color: AppColors.error, fontSize: 13)),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: cart.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              subtitle: 'Browse the marketplace to add products',
            );
          }
          final total = items.fold<double>(0, (sum, i) => sum + i.totalPrice);
          return Stack(
            children: [
              ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final product = item.product;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 72, height: 72,
                            child: product?.primaryImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: product!.primaryImageUrl!,
                                    fit: BoxFit.cover)
                                : Container(
                                    color: AppColors.surfaceElevated,
                                    child: const Icon(Icons.image_outlined,
                                        color: AppColors.textMuted)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product?.name ?? 'Unknown product',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${item.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Text('Qty: ${item.quantity}', style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary,
                            )),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                await SupabaseService.removeFromCart(item.id);
                                ref.refresh(cartProvider(user.id));
                              },
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.error, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Checkout bar
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total', style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted,
                            )),
                            Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.accent,
                            )),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 50, width: 160,
                        child: ElevatedButton.icon(
                          onPressed: () => showSnack(context, 'Checkout coming soon'),
                          icon: const Icon(Icons.payment_rounded, size: 18),
                          label: const Text('Checkout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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
