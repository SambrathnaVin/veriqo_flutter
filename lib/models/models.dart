import 'package:flutter/material.dart';
// ============================================================
// VERIQO - Data Models
// ============================================================

enum UserRole { buyer, seller, admin }

enum VerificationStatus { pending, approved, rejected }

enum ProductStatus { draft, pendingReview, approved, rejected, suspended }

enum OrderStatus { pending, confirmed, shipped, delivered, cancelled, refunded }

enum NotificationType {
  productApproved,
  productRejected,
  orderPlaced,
  orderShipped,
  orderDelivered,
  sellerVerified,
  sellerRejected,
  newProductReview,
  lowStock,
  general,
}

// ── Profile ──────────────────────────────────────────────────
class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        phone: json['phone'] as String?,
        role: UserRole.values.firstWhere(
          (e) => e.name == (json['role'] as String? ?? 'buyer'),
          orElse: () => UserRole.buyer,
        ),
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Profile copyWith({
    String? fullName,
    String? avatarUrl,
    String? phone,
    UserRole? role,
  }) =>
      Profile(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        isActive: isActive,
        createdAt: createdAt,
      );
}

// ── SellerProfile ─────────────────────────────────────────────
class SellerProfile {
  final String id;
  final String userId;
  final String businessName;
  final String? businessDescription;
  final String? businessAddress;
  final String nationalIdNumber;
  final String nationalIdFrontUrl;
  final String? nationalIdBackUrl;
  final String? selfieWithIdUrl;
  final VerificationStatus verificationStatus;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final int totalProducts;
  final double totalSales;
  final double rating;
  final DateTime createdAt;
  // joined
  final Profile? profile;

  const SellerProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessDescription,
    this.businessAddress,
    required this.nationalIdNumber,
    required this.nationalIdFrontUrl,
    this.nationalIdBackUrl,
    this.selfieWithIdUrl,
    required this.verificationStatus,
    this.rejectionReason,
    this.verifiedAt,
    required this.totalProducts,
    required this.totalSales,
    required this.rating,
    required this.createdAt,
    this.profile,
  });

  factory SellerProfile.fromJson(Map<String, dynamic> json) => SellerProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        businessName: json['business_name'] as String,
        businessDescription: json['business_description'] as String?,
        businessAddress: json['business_address'] as String?,
        nationalIdNumber: json['national_id_number'] as String? ?? '',
        nationalIdFrontUrl: json['national_id_front_url'] as String? ?? '',
        nationalIdBackUrl: json['national_id_back_url'] as String?,
        selfieWithIdUrl: json['selfie_with_id_url'] as String?,
        verificationStatus: VerificationStatus.values.firstWhere(
          (e) => e.name == (json['verification_status'] as String? ?? 'pending'),
          orElse: () => VerificationStatus.pending,
        ),
        rejectionReason: json['rejection_reason'] as String?,
        verifiedAt: json['verified_at'] != null
            ? DateTime.parse(json['verified_at'] as String)
            : null,
        totalProducts: json['total_products'] as int? ?? 0,
        totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['created_at'] as String),
        profile: json['profiles'] != null
            ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
            : null,
      );
}

// ── Category ──────────────────────────────────────────────────
class Category {
  final String id;
  final String name;
  final String slug;
  final String? iconName;
  final String? imageUrl;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.iconName,
    this.imageUrl,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        iconName: json['icon_name'] as String?,
        imageUrl: json['image_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}

// ── ProductImage ──────────────────────────────────────────────
class ProductImage {
  final String id;
  final String productId;
  final String url;
  final String? altText;
  final bool isPrimary;
  final int sortOrder;

  const ProductImage({
    required this.id,
    required this.productId,
    required this.url,
    this.altText,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        url: json['url'] as String,
        altText: json['alt_text'] as String?,
        isPrimary: json['is_primary'] as bool? ?? false,
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}

// ── Product ───────────────────────────────────────────────────
class Product {
  final String id;
  final String sellerId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final double? comparePrice;
  final String? sku;
  final String? barcode;
  final int stockQuantity;
  final ProductStatus status;
  final String? rejectionReason;
  final bool isFeatured;
  final int viewsCount;
  final int salesCount;
  final double rating;
  final int reviewsCount;
  final List<String> tags;
  final String? originCountry;
  final String? manufacturer;
  final DateTime createdAt;
  final List<ProductImage> images;
  final SellerProfile? seller;
  final Category? category;

  const Product({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.comparePrice,
    this.sku,
    this.barcode,
    required this.stockQuantity,
    required this.status,
    this.rejectionReason,
    required this.isFeatured,
    required this.viewsCount,
    required this.salesCount,
    required this.rating,
    required this.reviewsCount,
    required this.tags,
    this.originCountry,
    this.manufacturer,
    required this.createdAt,
    this.images = const [],
    this.seller,
    this.category,
  });

  String? get primaryImageUrl {
    final primary = images.where((i) => i.isPrimary).firstOrNull;
    return primary?.url ?? images.firstOrNull?.url;
  }

  double get discountPercent {
    if (comparePrice == null || comparePrice! <= price) return 0;
    return ((comparePrice! - price) / comparePrice! * 100);
  }

  static ProductStatus _parseStatus(String s) {
    final normalized = s.replaceAll('_', '').toLowerCase();
    for (final e in ProductStatus.values) {
      if (e.name.toLowerCase() == normalized) return e;
    }
    return ProductStatus.pendingReview;
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        sellerId: json['seller_id'] as String,
        categoryId: json['category_id'] as String?,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        comparePrice: (json['compare_price'] as num?)?.toDouble(),
        sku: json['sku'] as String?,
        barcode: json['barcode'] as String?,
        stockQuantity: json['stock_quantity'] as int? ?? 0,
        status: _parseStatus(json['status'] as String? ?? 'pending_review'),
        rejectionReason: json['rejection_reason'] as String?,
        isFeatured: json['is_featured'] as bool? ?? false,
        viewsCount: json['views_count'] as int? ?? 0,
        salesCount: json['sales_count'] as int? ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewsCount: json['reviews_count'] as int? ?? 0,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        originCountry: json['origin_country'] as String?,
        manufacturer: json['manufacturer'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        images: (json['product_images'] as List<dynamic>?)
                ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        seller: json['seller_profiles'] != null
            ? SellerProfile.fromJson(
                json['seller_profiles'] as Map<String, dynamic>)
            : null,
        category: json['categories'] != null
            ? Category.fromJson(json['categories'] as Map<String, dynamic>)
            : null,
      );
}

// ── Notification ──────────────────────────────────────────────
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  static NotificationType _parseType(String s) {
    final parts = s.split('_');
    final camel = parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
    return NotificationType.values.firstWhere(
      (e) => e.name == camel,
      orElse: () => NotificationType.general,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: _parseType(json['type'] as String? ?? 'general'),
        referenceId: json['reference_id'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

// ── CartItem ──────────────────────────────────────────────────
class CartItem {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final Product? product;

  const CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        productId: json['product_id'] as String,
        quantity: json['quantity'] as int,
        product: json['products'] != null
            ? Product.fromJson(json['products'] as Map<String, dynamic>)
            : null,
      );

  double get totalPrice => (product?.price ?? 0) * quantity;
}

// ── Admin Analytics Models ─────────────────────────────────────
class AdminAnalytics {
  final int totalUsers;
  final int activeSellers;
  final int totalProducts;
  final int pendingReviews;
  final int approvedProducts;
  final int rejectedProducts;
  final int draftProducts;
  final int suspendedProducts;
  final int totalSellerApplications;
  final int pendingSellers;
  final int approvedSellers;
  final int rejectedSellers;
  final List<TopSellerStat> topSellers;
  final List<CategoryStat> categoryBreakdown;
  final List<ActivityItem> recentActivity;

  const AdminAnalytics({
    required this.totalUsers,
    required this.activeSellers,
    required this.totalProducts,
    required this.pendingReviews,
    required this.approvedProducts,
    required this.rejectedProducts,
    required this.draftProducts,
    required this.suspendedProducts,
    required this.totalSellerApplications,
    required this.pendingSellers,
    required this.approvedSellers,
    required this.rejectedSellers,
    required this.topSellers,
    required this.categoryBreakdown,
    required this.recentActivity,
  });
}

class TopSellerStat {
  final String sellerId;
  final String businessName;
  final int productCount;
  final double rating;

  const TopSellerStat({
    required this.sellerId,
    required this.businessName,
    required this.productCount,
    required this.rating,
  });
}

class CategoryStat {
  final String categoryId;
  final String name;
  final int count;

  const CategoryStat({
    required this.categoryId,
    required this.name,
    required this.count,
  });
}

class ActivityItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime createdAt;

  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.createdAt,
  });
}

// ── Seller Order Models ────────────────────────────────────────
class SellerOrder {
  final String orderId;
  final String orderNumber;
  final String? buyerName;
  final OrderStatus status;
  final List<OrderItemDetail> items;
  final double sellerTotal;
  final DateTime createdAt;

  const SellerOrder({
    required this.orderId,
    required this.orderNumber,
    this.buyerName,
    required this.status,
    required this.items,
    required this.sellerTotal,
    required this.createdAt,
  });

  factory SellerOrder.fromJson(
      Map<String, dynamic> json, List<OrderItemDetail> items) {
    final total = items.fold(0.0, (sum, i) => sum + i.totalPrice);
    return SellerOrder(
      orderId: json['id'] as String,
      orderNumber: json['order_number'] as String,
      buyerName:
          (json['profiles'] as Map<String, dynamic>?)?['full_name'] as String?,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      items: items,
      sellerTotal: total,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class OrderItemDetail {
  final String id;
  final String orderId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Product? product;

  const OrderItemDetail({
    required this.id,
    required this.orderId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.product,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) =>
      OrderItemDetail(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unit_price'] as num).toDouble(),
        totalPrice: (json['total_price'] as num).toDouble(),
        product: json['products'] != null
            ? Product.fromJson(json['products'] as Map<String, dynamic>)
            : null,
      );
}
