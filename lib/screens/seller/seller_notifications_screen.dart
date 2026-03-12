import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class SellerNotificationsScreen extends ConsumerWidget {
  const SellerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));
    final notifs = ref.watch(notificationsProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(backgroundColor: AppColors.primary, title: const Text('Notifications')),
      body: notifs.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.notifications_none_rounded, title: 'No notifications');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final n = list[i];
              final color = n.type == NotificationType.productApproved || n.type == NotificationType.sellerVerified
                  ? AppColors.success
                  : n.type == NotificationType.productRejected || n.type == NotificationType.sellerRejected
                      ? AppColors.error
                      : AppColors.info;
              return GestureDetector(
                onTap: () async {
                  if (!n.isRead) {
                    await SupabaseService.markNotificationRead(n.id);
                    ref.refresh(notificationsProvider(user.id));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.isRead ? AppColors.surfaceCard : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: n.isRead ? AppColors.surfaceBorder : color.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          n.type == NotificationType.productApproved ? Icons.check_circle_outline_rounded
                              : n.type == NotificationType.productRejected ? Icons.cancel_outlined
                              : Icons.notifications_outlined,
                          color: color, size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: n.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                            )),
                            const SizedBox(height: 3),
                            Text(n.body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                            const SizedBox(height: 5),
                            Text(timeago.format(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        Container(width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
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
