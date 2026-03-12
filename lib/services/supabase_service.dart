import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';


class SupabaseService {
  static SupabaseClient get supabase => Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────
  static Future<AuthResponse> signIn(String email, String password) =>
      supabase.auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUp(
          String email, String password, String fullName) =>
      supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

  static Future<void> signOut() => supabase.auth.signOut();

  static User? get currentUser => supabase.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      supabase.auth.onAuthStateChange;

  // ── Profile ───────────────────────────────────────────────
  static Future<Profile?> getProfile(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data != null ? Profile.fromJson(data) : null;
  }

  static Future<void> updateProfile(
      String userId, Map<String, dynamic> updates) async {
    await supabase.from('profiles').update(updates).eq('id', userId);
  }

  static Future<String?> uploadAvatar(String userId, File file) async {
    final ext = file.path.split('.').last;
    final path = '$userId/avatar.$ext';
    await supabase.storage.from('avatars').upload(path, file,
        fileOptions: const FileOptions(upsert: true));
    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  // ── Seller ────────────────────────────────────────────────
  static Future<SellerProfile?> getSellerProfile(String userId) async {
    final data = await supabase
        .from('seller_profiles')
        .select('*, profiles!seller_profiles_user_id_fkey(*)')
        .eq('user_id', userId)
        .maybeSingle();
    return data != null ? SellerProfile.fromJson(data) : null;
  }

  static Future<List<SellerProfile>> getAllSellers({
    VerificationStatus? status,
  }) async {
    var query = supabase
        .from('seller_profiles')
        .select('*, profiles!seller_profiles_user_id_fkey(*)');
    if (status != null) {
      query = query.eq('verification_status', status.name);
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => SellerProfile.fromJson(e)).toList();
  }

  static Future<void> updateSellerVerification(
      String sellerId, VerificationStatus status,
      {String? reason}) async {
    final updates = {
      'verification_status': status.name,
      if (reason != null) 'rejection_reason': reason,
      if (status == VerificationStatus.approved)
        'verified_at': DateTime.now().toIso8601String(),
    };
    await supabase
        .from('seller_profiles')
        .update(updates)
        .eq('id', sellerId);
  }

  static Future<String> uploadSellerDocument(
      String userId, File file, String docType) async {
    final ext = file.path.split('.').last;
    final path = '$userId/$docType.$ext';
    await supabase.storage.from('seller-documents').upload(path, file,
        fileOptions: const FileOptions(upsert: true));
    return path;
  }

  static String getDocumentUrl(String path) =>
      supabase.storage.from('seller-documents').getPublicUrl(path);

  static Future<SellerProfile> createSellerProfile(
      Map<String, dynamic> data) async {
    final result = await supabase
        .from('seller_profiles')
        .insert(data)
        .select()
        .single();
    return SellerProfile.fromJson(result);
  }

  // ── Categories ────────────────────────────────────────────
  static Future<List<Category>> getCategories() async {
    final data = await supabase
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (data as List).map((e) => Category.fromJson(e)).toList();
  }

  // ── Products ──────────────────────────────────────────────
  static Future<List<Product>> getApprovedProducts({
    String? categoryId,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = supabase
        .from('products')
        .select(
            '*, product_images(*), seller_profiles(*, profiles!seller_profiles_user_id_fkey(*)), categories(*)')
        .eq('status', 'approved');

    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  static Future<List<Product>> getSellerProducts(String sellerId) async {
    final data = await supabase
        .from('products')
        .select('*, product_images(*), categories(*)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  static Future<List<Product>> getAllProductsAdmin({
    ProductStatus? status,
  }) async {
    var query = supabase.from('products').select(
        '*, product_images(*), seller_profiles(*, profiles!seller_profiles_user_id_fkey(*)), categories(*)');

    if (status != null) {
      final dbStatus = _toDbStatus(status);
      query = query.eq('status', dbStatus);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  static Future<Product?> getProductById(String productId) async {
    final data = await supabase
        .from('products')
        .select(
            '*, product_images(*), seller_profiles(*, profiles!seller_profiles_user_id_fkey(*)), categories(*)')
        .eq('id', productId)
        .maybeSingle();
    return data != null ? Product.fromJson(data) : null;
  }

  static Future<Product> createProduct(Map<String, dynamic> data) async {
    final result =
        await supabase.from('products').insert(data).select().single();
    return Product.fromJson(result);
  }

  /// Update product fields — used by sellers editing their product.
  static Future<void> updateProduct(
      String productId, Map<String, dynamic> updates) async {
    await supabase.from('products').update(updates).eq('id', productId);
  }

  static Future<void> updateProductStatus(
      String productId, ProductStatus status,
      {String? reason}) async {
    await supabase.from('products').update({
      'status': _toDbStatus(status),
      if (reason != null) 'rejection_reason': reason,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
  }

  static Future<String> uploadProductImage(
      String sellerId, File file, String productId, int index) async {
    final ext = file.path.split('.').last;
    final path = '$sellerId/$productId/img_$index.$ext';
    await supabase.storage.from('products').upload(path, file,
        fileOptions: const FileOptions(upsert: true));
    return supabase.storage.from('products').getPublicUrl(path);
  }

  static Future<void> addProductImage(
      String productId, String url, bool isPrimary) async {
    await supabase.from('product_images').insert({
      'product_id': productId,
      'url': url,
      'is_primary': isPrimary,
      'sort_order': 0,
    });
  }

  // ── Orders (Seller view) ──────────────────────────────────
  static Future<List<SellerOrder>> getSellerOrders(String sellerId) async {
    // Fetch order_items for this seller, with order + product data joined
    final itemsData = await supabase
        .from('order_items')
        .select('*, orders(*, profiles!orders_buyer_id_fkey(*)), products(*, product_images(*))')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    // Group items by order_id
    final Map<String, Map<String, dynamic>> ordersMap = {};
    final Map<String, List<OrderItemDetail>> itemsMap = {};

    for (final row in (itemsData as List)) {
      final orderData = row['orders'] as Map<String, dynamic>;
      final orderId = orderData['id'] as String;

      ordersMap[orderId] ??= orderData;
      itemsMap[orderId] ??= [];
      itemsMap[orderId]!.add(OrderItemDetail.fromJson(row));
    }

    return ordersMap.entries.map((e) {
      return SellerOrder.fromJson(e.value, itemsMap[e.key] ?? []);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> updateOrderStatus(
      String orderId, OrderStatus status) async {
    final dbStatus = status.name;
    await supabase.from('orders').update({
      'status': dbStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  // ── Notifications ─────────────────────────────────────────
  static Future<List<AppNotification>> getNotifications(
      String userId) async {
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  static Future<int> getUnreadCount(String userId) async {
    final data = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (data as List).length;
  }

  static Future<void> markNotificationRead(String notifId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notifId);
  }

  static Future<void> markAllNotificationsRead(String userId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // ── Cart ──────────────────────────────────────────────────
  static Future<List<CartItem>> getCartItems(String userId) async {
    final data = await supabase
        .from('cart_items')
        .select('*, products(*, product_images(*))')
        .eq('user_id', userId);
    return (data as List).map((e) => CartItem.fromJson(e)).toList();
  }

  static Future<void> addToCart(
      String userId, String productId, int qty) async {
    await supabase.from('cart_items').upsert({
      'user_id': userId,
      'product_id': productId,
      'quantity': qty,
    }, onConflict: 'user_id,product_id');
  }

  static Future<void> removeFromCart(String cartItemId) async {
    await supabase.from('cart_items').delete().eq('id', cartItemId);
  }

  static Future<void> clearCart(String userId) async {
    await supabase.from('cart_items').delete().eq('user_id', userId);
  }

  // ── Admin Stats ───────────────────────────────────────────
  static Future<Map<String, int>> getAdminStats() async {
    final results = await Future.wait([
      supabase.from('profiles').select('id').eq('role', 'buyer'),
      supabase.from('profiles').select('id').eq('role', 'seller'),
      supabase
          .from('seller_profiles')
          .select('id')
          .eq('verification_status', 'pending'),
      supabase.from('products').select('id').eq('status', 'pending_review'),
      supabase.from('products').select('id').eq('status', 'approved'),
    ]);

    return {
      'buyers': (results[0] as List).length,
      'sellers': (results[1] as List).length,
      'pendingSellers': (results[2] as List).length,
      'pendingProducts': (results[3] as List).length,
      'approvedProducts': (results[4] as List).length,
    };
  }

  // ── Admin Analytics ───────────────────────────────────────
  static Future<AdminAnalytics> getAdminAnalytics() async {
    final results = await Future.wait([
      // 0: total users (non-admin)
      supabase.from('profiles').select('id').neq('role', 'admin'),
      // 1: active sellers
      supabase.from('seller_profiles').select('id').eq('verification_status', 'approved'),
      // 2: all products with category
      supabase.from('products').select('id, status, category_id, categories(name)'),
      // 3: seller applications breakdown
      supabase.from('seller_profiles').select('id, verification_status'),
      // 4: top sellers (seller_id, business_name, count)
      supabase
          .from('products')
          .select('seller_id, seller_profiles(business_name)')
          .eq('status', 'approved'),
      // 5: recent notifications (admin activity proxy)
      supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(20),
    ]);

    final allProducts = results[2] as List;
    final approvedCount = allProducts.where((p) => p['status'] == 'approved').length;
    final pendingCount = allProducts.where((p) => p['status'] == 'pending_review').length;
    final rejectedCount = allProducts.where((p) => p['status'] == 'rejected').length;
    final draftCount = allProducts.where((p) => p['status'] == 'draft').length;
    final suspendedCount = allProducts.where((p) => p['status'] == 'suspended').length;

    // Seller funnel
    final allApplications = results[3] as List;
    final pendingSellers = allApplications.where((s) => s['verification_status'] == 'pending').length;
    final approvedSellers = allApplications.where((s) => s['verification_status'] == 'approved').length;
    final rejectedSellers = allApplications.where((s) => s['verification_status'] == 'rejected').length;

    // Top sellers
    final sellerProductCounts = <String, Map<String, dynamic>>{};
    for (final p in results[4] as List) {
      final sid = p['seller_id'] as String;
      sellerProductCounts[sid] ??= {
        'business_name': (p['seller_profiles'] as Map<String, dynamic>?)?['business_name'] ?? 'Unknown',
        'count': 0,
      };
      sellerProductCounts[sid]!['count'] = (sellerProductCounts[sid]!['count'] as int) + 1;
    }
    final topSellers = sellerProductCounts.entries
        .map((e) => TopSellerStat(
              sellerId: e.key,
              businessName: e.value['business_name'] as String,
              productCount: e.value['count'] as int,
              rating: 0,
            ))
        .toList()
      ..sort((a, b) => b.productCount.compareTo(a.productCount));

    // Category breakdown
    final catCounts = <String, Map<String, dynamic>>{};
    for (final p in allProducts) {
      final cat = p['categories'] as Map<String, dynamic>?;
      if (cat == null) continue;
      final cid = p['category_id'] as String? ?? 'unknown';
      catCounts[cid] ??= {'name': cat['name'], 'count': 0};
      catCounts[cid]!['count'] = (catCounts[cid]!['count'] as int) + 1;
    }
    final categoryBreakdown = catCounts.entries
        .map((e) => CategoryStat(categoryId: e.key, name: e.value['name'] as String, count: e.value['count'] as int))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // Recent activity from notifications
    final recentActivity = (results[5] as List).map((n) {
      final notif = AppNotification.fromJson(n);
      final (icon, color) = _iconColorForType(notif.type);
      return ActivityItem(
        title: notif.title,
        subtitle: notif.body,
        icon: icon,
        color: color,
        createdAt: notif.createdAt,
      );
    }).toList();

    return AdminAnalytics(
      totalUsers: (results[0] as List).length,
      activeSellers: (results[1] as List).length,
      totalProducts: allProducts.length,
      pendingReviews: pendingCount,
      approvedProducts: approvedCount,
      rejectedProducts: rejectedCount,
      draftProducts: draftCount,
      suspendedProducts: suspendedCount,
      totalSellerApplications: allApplications.length,
      pendingSellers: pendingSellers,
      approvedSellers: approvedSellers,
      rejectedSellers: rejectedSellers,
      topSellers: topSellers.take(5).toList(),
      categoryBreakdown: categoryBreakdown.take(8).toList(),
      recentActivity: recentActivity,
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  static String _toDbStatus(ProductStatus status) => status.name
      .replaceAllMapped(
          RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
      .replaceAll(RegExp(r'^_'), '');

  static (IconData, Color) _iconColorForType(NotificationType type) =>
      switch (type) {
        NotificationType.sellerVerified => (Icons.verified_rounded, const Color(0xFF10B981)),
        NotificationType.sellerRejected => (Icons.store_outlined, const Color(0xFFEF4444)),
        NotificationType.productApproved => (Icons.inventory_2_rounded, const Color(0xFF10B981)),
        NotificationType.productRejected => (Icons.block_rounded, const Color(0xFFEF4444)),
        NotificationType.orderPlaced => (Icons.shopping_bag_rounded, const Color(0xFF00D4FF)),
        NotificationType.lowStock => (Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
        _ => (Icons.notifications_rounded, const Color(0xFF94A3B8)),
      };
}