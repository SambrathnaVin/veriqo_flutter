import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

final _sellerStatusFilterProvider =
    StateProvider<VerificationStatus?>((ref) => null);

class AdminSellersScreen extends ConsumerWidget {
  const AdminSellersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_sellerStatusFilterProvider);
    final sellers = ref.watch(adminSellersProvider(filter));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Seller Applications'),
      ),
      body: Column(
        children: [
          // Filter tabs
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter == null,
                  onTap: () => ref
                      .read(_sellerStatusFilterProvider.notifier)
                      .state = null,
                ),
                _FilterChip(
                  label: 'Pending',
                  selected: filter == VerificationStatus.pending,
                  color: AppColors.pending,
                  onTap: () => ref
                      .read(_sellerStatusFilterProvider.notifier)
                      .state = VerificationStatus.pending,
                ),
                _FilterChip(
                  label: 'Approved',
                  selected: filter == VerificationStatus.approved,
                  color: AppColors.approved,
                  onTap: () => ref
                      .read(_sellerStatusFilterProvider.notifier)
                      .state = VerificationStatus.approved,
                ),
                _FilterChip(
                  label: 'Rejected',
                  selected: filter == VerificationStatus.rejected,
                  color: AppColors.rejected,
                  onTap: () => ref
                      .read(_sellerStatusFilterProvider.notifier)
                      .state = VerificationStatus.rejected,
                ),
              ],
            ),
          ),

          Expanded(
            child: sellers.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.store_outlined,
                    title: 'No applications found',
                    subtitle: 'Nothing matches this filter',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _SellerApplicationCard(
                    seller: items[i],
                    onRefresh: () =>
                        ref.refresh(adminSellersProvider(filter)),
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
                  onAction: () =>
                      ref.refresh(adminSellersProvider(filter)),
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

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? c.withOpacity(0.15)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? c : AppColors.surfaceBorder),
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

// ── Seller Application Card ───────────────────────────────────
class _SellerApplicationCard extends StatefulWidget {
  final SellerProfile seller;
  final VoidCallback onRefresh;

  const _SellerApplicationCard(
      {required this.seller, required this.onRefresh});

  @override
  State<_SellerApplicationCard> createState() =>
      _SellerApplicationCardState();
}

class _SellerApplicationCardState extends State<_SellerApplicationCard> {
  bool _loading = false;
  bool _expanded = false;

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.updateSellerVerification(
          widget.seller.id, VerificationStatus.approved);
      if (mounted) {
        showSnack(context, 'Seller account approved. They can now upload products.');
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
      await SupabaseService.updateSellerVerification(
          widget.seller.id, VerificationStatus.rejected,
          reason: reason.trim());
      if (mounted) {
        showSnack(context, 'Seller application rejected');
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Rejection Reason',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Provide a reason for rejection...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.surfaceBorder),
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

  Future<void> _viewDocument(BuildContext ctx, String path,
      String title) async {
    final url = SupabaseService.getDocumentUrl(path);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppColors.textMuted, size: 48))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text('Close',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.seller;
    final isPending = s.verificationStatus == VerificationStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isPending
              ? AppColors.pending.withOpacity(0.35)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      AppColors.accent,
                      AppColors.accentSecondary
                    ]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.businessName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (s.profile != null)
                        Text(
                          s.profile!.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                StatusBadge.fromVerificationStatus(s.verificationStatus),
              ],
            ),
          ),

          // Quick info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _InfoChip(
                    icon: Icons.badge_outlined,
                    label: 'ID: ${s.nationalIdNumber.isNotEmpty ? '${s.nationalIdNumber.substring(0, s.nationalIdNumber.length > 4 ? 4 : s.nationalIdNumber.length)}****' : 'N/A'}'),
                if (s.businessAddress != null)
                  _InfoChip(
                      icon: Icons.location_on_outlined,
                      label: s.businessAddress!),
                _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label:
                        'Applied ${_formatDate(s.createdAt)}'),
              ],
            ),
          ),

          // Expand toggle
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Text('View documents',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
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

          // Expanded: document viewer
          if (_expanded) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.surfaceBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.businessDescription != null &&
                      s.businessDescription!.isNotEmpty) ...[
                    const Text('Business description',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      s.businessDescription!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text('Identity documents',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _DocButton(
                        label: 'ID Front',
                        icon: Icons.credit_card_rounded,
                        available: s.nationalIdFrontUrl.isNotEmpty,
                        onTap: s.nationalIdFrontUrl.isNotEmpty
                            ? () => _viewDocument(context,
                                s.nationalIdFrontUrl, 'National ID – Front')
                            : null,
                      ),
                      const SizedBox(width: 8),
                      _DocButton(
                        label: 'ID Back',
                        icon: Icons.credit_card_outlined,
                        available: s.nationalIdBackUrl != null,
                        onTap: s.nationalIdBackUrl != null
                            ? () => _viewDocument(context,
                                s.nationalIdBackUrl!, 'National ID – Back')
                            : null,
                      ),
                      const SizedBox(width: 8),
                      _DocButton(
                        label: 'Selfie',
                        icon: Icons.face_rounded,
                        available: s.selfieWithIdUrl != null,
                        onTap: s.selfieWithIdUrl != null
                            ? () => _viewDocument(context,
                                s.selfieWithIdUrl!, 'Selfie with ID')
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Action buttons – pending only
          if (isPending) ...[
            const Divider(height: 1, color: AppColors.surfaceBorder),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _reject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _approve,
                        icon: _loading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary))
                            : const Icon(Icons.verified_rounded,
                                size: 16),
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
          if (s.verificationStatus == VerificationStatus.rejected &&
              s.rejectionReason != null) ...[
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
                      s.rejectionReason!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 2),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _DocButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool available;
  final VoidCallback? onTap;

  const _DocButton({
    required this.label,
    required this.icon,
    required this.available,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: available
                ? AppColors.accent.withOpacity(0.1)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: available
                  ? AppColors.accent.withOpacity(0.3)
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: available
                      ? AppColors.accent
                      : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: available
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
              ),
              Text(
                available ? 'View' : 'Not provided',
                style: TextStyle(
                  fontSize: 10,
                  color: available
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
