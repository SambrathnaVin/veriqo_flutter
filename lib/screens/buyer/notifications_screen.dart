import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType type) => switch (type) {
    NotificationType.productApproved => Icons.check_circle_outline_rounded,
    NotificationType.productRejected => Icons.cancel_outlined,
    NotificationType.orderPlaced     => Icons.shopping_bag_outlined,
    NotificationType.orderShipped    => Icons.local_shipping_outlined,
    NotificationType.orderDelivered  => Icons.done_all_rounded,
    NotificationType.sellerVerified  => Icons.verified_outlined,
    NotificationType.sellerRejected  => Icons.gpp_bad_outlined,
    _                                => Icons.notifications_outlined,
  };

  Color _colorFor(NotificationType type) => switch (type) {
    NotificationType.productApproved => AppColors.success,
    NotificationType.productRejected => AppColors.error,
    NotificationType.orderDelivered  => AppColors.success,
    NotificationType.sellerVerified  => AppColors.accent,
    NotificationType.sellerRejected  => AppColors.error,
    _                                => AppColors.info,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    final notifs = ref.watch(notificationsProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Notifications'),
        actions: [
          notifs.when(
            data: (list) => list.any((n) => !n.isRead)
                ? TextButton(
                    onPressed: () async {
                      await SupabaseService.markAllNotificationsRead(user.id);
                      ref.refresh(notificationsProvider(user.id));
                    },
                    child: const Text('Mark all read',
                        style: TextStyle(color: AppColors.accent, fontSize: 13)),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifs.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              subtitle: 'You\'re all caught up',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final n = list[i];
              final color = _colorFor(n.type);
              return GestureDetector(
                onTap: () async {
                  if (!n.isRead) {
                    await SupabaseService.markNotificationRead(n.id);
                    ref.refresh(notificationsProvider(user.id));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: n.isRead ? AppColors.surfaceCard : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: n.isRead ? AppColors.surfaceBorder : color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_iconFor(n.type), color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(n.title, style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: n.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                                  )),
                                ),
                                if (!n.isRead)
                                  Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(n.body, style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary, height: 1.4,
                            )),
                            const SizedBox(height: 6),
                            Text(timeago.format(n.createdAt),
                                style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}
