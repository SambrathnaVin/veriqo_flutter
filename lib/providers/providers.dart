import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

// ── Auth State ────────────────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.currentUser;
});

// ── Profile ───────────────────────────────────────────────────
final profileProvider =
    FutureProvider.family<Profile?, String>((ref, userId) async {
  return SupabaseService.getProfile(userId);
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return SupabaseService.getProfile(user.id);
});

// ── Seller Profile ────────────────────────────────────────────
final sellerProfileProvider =
    FutureProvider.family<SellerProfile?, String>((ref, userId) async {
  return SupabaseService.getSellerProfile(userId);
});

final currentSellerProfileProvider =
    FutureProvider<SellerProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return SupabaseService.getSellerProfile(user.id);
});

// ── Categories ─────────────────────────────────────────────────
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return SupabaseService.getCategories();
});

// ── Products ───────────────────────────────────────────────────
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider);
  return SupabaseService.getApprovedProducts(
    categoryId: category,
    searchQuery: search.isNotEmpty ? search : null,
  );
});

final sellerProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, sellerId) async {
  return SupabaseService.getSellerProducts(sellerId);
});

final productDetailProvider =
    FutureProvider.family<Product?, String>((ref, productId) async {
  return SupabaseService.getProductById(productId);
});

// ── Admin ──────────────────────────────────────────────────────
final adminProductsProvider =
    FutureProvider.family<List<Product>, ProductStatus?>((ref, status) async {
  return SupabaseService.getAllProductsAdmin(status: status);
});

final adminSellersProvider =
    FutureProvider.family<List<SellerProfile>, VerificationStatus?>(
        (ref, status) async {
  return SupabaseService.getAllSellers(status: status);
});

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return SupabaseService.getAdminStats();
});

final adminAnalyticsProvider = FutureProvider<AdminAnalytics>((ref) async {
  return SupabaseService.getAdminAnalytics();
});

// ── Seller Orders ──────────────────────────────────────────────
final sellerOrdersProvider =
    FutureProvider.family<List<SellerOrder>, String>((ref, sellerId) async {
  return SupabaseService.getSellerOrders(sellerId);
});

// ── Notifications ──────────────────────────────────────────────
final notificationsProvider =
    FutureProvider.family<List<AppNotification>, String>((ref, userId) async {
  return SupabaseService.getNotifications(userId);
});

final unreadCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  return SupabaseService.getUnreadCount(userId);
});

// ── Cart ───────────────────────────────────────────────────────
final cartProvider =
    FutureProvider.family<List<CartItem>, String>((ref, userId) async {
  return SupabaseService.getCartItems(userId);
});

// ── All Profiles (admin) ───────────────────────────────────────
final allUsersProvider = FutureProvider<List<Profile>>((ref) async {
  final data = await SupabaseService.supabase
      .from('profiles')
      .select()
      .order('created_at', ascending: false);
  return (data as List).map((e) => Profile.fromJson(e)).toList();
});
