import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _statuses = [null, OrderStatus.pending, OrderStatus.confirmed, OrderStatus.shipped, OrderStatus.delivered];
  static const _labels = ['All', 'Pending', 'Confirmed', 'Shipped', 'Delivered'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    if (user == null) return const SizedBox();

    final sellerAsync = ref.watch(currentSellerProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: sellerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
        data: (seller) {
          if (seller == null) return const EmptyState(icon: Icons.store_outlined, title: 'No seller profile', subtitle: '');
          return _OrdersBody(seller: seller, tabs: _tabs, statuses: _statuses, labels: _labels);
        },
      ),
    );
  }
}

class _OrdersBody extends ConsumerWidget {
  final SellerProfile seller;
  final TabController tabs;
  final List<OrderStatus?> statuses;
  final List<String> labels;

  const _OrdersBody({
    required this.seller,
    required this.tabs,
    required this.statuses,
    required this.labels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(sellerOrdersProvider(seller.id));

    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        SliverAppBar(
          backgroundColor: AppColors.primary,
          floating: true,
          snap: true,
          expandedHeight: 130,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentSecondary]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 30),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text('Track & manage customer orders', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
          bottom: TabBar(
            controller: tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.accent,
            indicatorWeight: 2,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            dividerColor: AppColors.surfaceBorder,
            tabs: labels.map((l) => Tab(text: l)).toList(),
          ),
        ),
      ],
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (orders) {
          return TabBarView(
            controller: tabs,
            children: statuses.map((status) {
              final filtered = status == null
                  ? orders
                  : orders.where((o) => o.status == status).toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: status == null ? 'No orders' : 'No ${labels[statuses.indexOf(status)].toLowerCase()} orders',
                  subtitle: 'Orders for your products will appear here',
                );
              }

              return RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () async => ref.invalidate(sellerOrdersProvider(seller.id)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) => _OrderCard(order: filtered[i], sellerId: seller.id),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final SellerOrder order;
  final String sellerId;

  const _OrderCard({required this.order, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy · h:mm a').format(order.createdAt),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                _StatusChip(order.status),
              ],
            ),
          ),

          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Items
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                if (item.product?.primaryImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item.product!.primaryImageUrl!,
                      width: 44, height: 44, fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 20),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product?.name ?? 'Product',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Qty: ${item.quantity} · \$${item.unitPrice.toStringAsFixed(2)} each',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textAccent, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
          )),

          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Footer: total + action
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buyer: ${order.buyerName ?? 'Customer'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      'Total: \$${order.sellerTotal.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                if (_nextStatus(order.status) != null)
                  _AdvanceButton(
                    order: order,
                    sellerId: sellerId,
                    next: _nextStatus(order.status)!,
                    ref: ref,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  OrderStatus? _nextStatus(OrderStatus s) => switch (s) {
    OrderStatus.pending => OrderStatus.confirmed,
    OrderStatus.confirmed => OrderStatus.shipped,
    OrderStatus.shipped => OrderStatus.delivered,
    _ => null,
  };
}

class _AdvanceButton extends StatefulWidget {
  final SellerOrder order;
  final String sellerId;
  final OrderStatus next;
  final WidgetRef ref;

  const _AdvanceButton({required this.order, required this.sellerId, required this.next, required this.ref});

  @override
  State<_AdvanceButton> createState() => _AdvanceButtonState();
}

class _AdvanceButtonState extends State<_AdvanceButton> {
  bool _loading = false;

  String _label(OrderStatus s) => switch (s) {
    OrderStatus.confirmed => 'Confirm',
    OrderStatus.shipped => 'Mark Shipped',
    OrderStatus.delivered => 'Mark Delivered',
    _ => '',
  };

  Future<void> _advance() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.updateOrderStatus(widget.order.orderId, widget.next);
      widget.ref.invalidate(sellerOrdersProvider(widget.sellerId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _loading
      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
      : TextButton(
          onPressed: _advance,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.accent.withOpacity(0.1),
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              side: const BorderSide(color: AppColors.accent, width: 0.5),
            ),
          ),
          child: Text(_label(widget.next), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        );
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      OrderStatus.pending => ('Pending', AppColors.pending),
      OrderStatus.confirmed => ('Confirmed', AppColors.info),
      OrderStatus.shipped => ('Shipped', AppColors.accentSecondary),
      OrderStatus.delivered => ('Delivered', AppColors.success),
      OrderStatus.cancelled => ('Cancelled', AppColors.error),
      OrderStatus.refunded => ('Refunded', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}