import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.currentUser;
    if (user == null) return const SizedBox();

    final notifsAsync = ref.watch(notificationsProvider(user.id));

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentSecondary]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            Text('Actions requiring your attention', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    // Mark all read
                    notifsAsync.maybeWhen(
                      data: (notifs) {
                        final unread = notifs.where((n) => !n.isRead).toList();
                        if (unread.isEmpty) return const SizedBox();
                        return TextButton(
                          onPressed: () async {
                            await SupabaseService.markAllNotificationsRead(user.id);
                            ref.invalidate(notificationsProvider(user.id));
                            ref.invalidate(unreadCountProvider(user.id));
                          },
                          child: const Text('Mark all read', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                        );
                      },
                      orElse: () => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          notifsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
            ),
            data: (notifs) {
              if (notifs.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'All caught up',
                    subtitle: 'New seller applications and product submissions will appear here',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _AdminNotifTile(
                        notif: notifs[i],
                        onTap: () => _handleTap(context, ref, notifs[i], user.id),
                        onMarkRead: notifs[i].isRead
                            ? null
                            : () async {
                                await SupabaseService.markNotificationRead(notifs[i].id);
                                ref.invalidate(notificationsProvider(user.id));
                                ref.invalidate(unreadCountProvider(user.id));
                              },
                      ),
                    ),
                    childCount: notifs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, AppNotification notif, String userId) async {
    // Mark as read
    if (!notif.isRead) {
      await SupabaseService.markNotificationRead(notif.id);
      ref.invalidate(notificationsProvider(userId));
      ref.invalidate(unreadCountProvider(userId));
    }

    if (!context.mounted) return;

    // Navigate to relevant screen
    switch (notif.type) {
      case NotificationType.sellerVerified:
      case NotificationType.sellerRejected:
        context.go('/admin/sellers');
        break;
      case NotificationType.productApproved:
      case NotificationType.productRejected:
        context.go('/admin/products');
        break;
      default:
        break;
    }
  }
}

class _AdminNotifTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  const _AdminNotifTile({
    required this.notif,
    required this.onTap,
    this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(notif.type);
    final isUnread = !notif.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.surfaceElevated : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isUnread ? color.withOpacity(0.3) : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeago.format(notif.createdAt),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      if (onMarkRead != null)
                        GestureDetector(
                          onTap: onMarkRead,
                          child: const Text(
                            'Mark read',
                            style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      // Action hint
                      if (_actionLabel(notif.type) != null)
                        Row(
                          children: [
                            Text(
                              _actionLabel(notif.type)!,
                              style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.accent, size: 10),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _iconAndColor(NotificationType type) => switch (type) {
    NotificationType.sellerVerified => (Icons.verified_rounded, AppColors.success),
    NotificationType.sellerRejected => (Icons.store_outlined, AppColors.error),
    NotificationType.productApproved => (Icons.inventory_2_rounded, AppColors.success),
    NotificationType.productRejected => (Icons.block_rounded, AppColors.error),
    NotificationType.orderPlaced => (Icons.shopping_bag_rounded, AppColors.accent),
    NotificationType.orderShipped => (Icons.local_shipping_rounded, AppColors.info),
    NotificationType.orderDelivered => (Icons.check_circle_rounded, AppColors.success),
    NotificationType.lowStock => (Icons.warning_amber_rounded, AppColors.warning),
    NotificationType.newProductReview => (Icons.star_rounded, AppColors.warning),
    NotificationType.general => (Icons.notifications_rounded, AppColors.textSecondary),
  };

  String? _actionLabel(NotificationType type) => switch (type) {
    NotificationType.sellerVerified || NotificationType.sellerRejected => 'View Sellers',
    NotificationType.productApproved || NotificationType.productRejected => 'View Products',
    _ => null,
  };
}
