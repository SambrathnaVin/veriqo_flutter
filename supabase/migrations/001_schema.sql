-- ============================================================
-- VERIQO - Supabase Database Schema
-- Run in order in Supabase SQL Editor
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- ENUMS
-- ============================================================
CREATE TYPE user_role AS ENUM ('buyer', 'seller', 'admin');
CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE product_status AS ENUM ('draft', 'pending_review', 'approved', 'rejected', 'suspended');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded');
CREATE TYPE notification_type AS ENUM (
  'product_approved', 'product_rejected', 'order_placed',
  'order_shipped', 'order_delivered', 'seller_verified',
  'seller_rejected', 'new_product_review', 'low_stock', 'general'
);

-- ============================================================
-- PROFILES TABLE
-- ============================================================
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  role user_role DEFAULT 'buyer',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- SELLER PROFILES TABLE
-- ============================================================
CREATE TABLE seller_profiles (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  business_name TEXT NOT NULL,
  business_description TEXT,
  business_address TEXT,
  national_id_number TEXT NOT NULL,
  national_id_front_url TEXT NOT NULL,
  national_id_back_url TEXT,
  selfie_with_id_url TEXT,
  verification_status verification_status DEFAULT 'pending',
  rejection_reason TEXT,
  verified_at TIMESTAMPTZ,
  verified_by UUID REFERENCES profiles(id),
  total_products INTEGER DEFAULT 0,
  total_sales NUMERIC(12,2) DEFAULT 0,
  rating NUMERIC(3,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE seller_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Sellers can view their own profile"
  ON seller_profiles FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Sellers can update their own profile"
  ON seller_profiles FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all seller profiles"
  ON seller_profiles FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- CATEGORIES TABLE
-- ============================================================
CREATE TABLE categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  icon_name TEXT,
  image_url TEXT,
  parent_id UUID REFERENCES categories(id),
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories are publicly readable" ON categories FOR SELECT USING (true);
CREATE POLICY "Admins can manage categories" ON categories FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Insert default categories
INSERT INTO categories (name, slug, icon_name, sort_order) VALUES
('Electronics', 'electronics', 'devices', 1),
('Fashion', 'fashion', 'shirt', 2),
('Home & Garden', 'home-garden', 'home', 3),
('Sports & Outdoor', 'sports', 'sports', 4),
('Beauty & Health', 'beauty', 'spa', 5),
('Books & Media', 'books', 'book', 6),
('Food & Grocery', 'food', 'restaurant', 7),
('Automotive', 'automotive', 'car', 8);

-- ============================================================
-- PRODUCTS TABLE
-- ============================================================
CREATE TABLE products (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  seller_id UUID REFERENCES seller_profiles(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id),
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  compare_price NUMERIC(12,2),
  sku TEXT UNIQUE,
  barcode TEXT,
  stock_quantity INTEGER DEFAULT 0,
  low_stock_threshold INTEGER DEFAULT 5,
  weight NUMERIC(8,2),
  status product_status DEFAULT 'pending_review',
  rejection_reason TEXT,
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES profiles(id),
  is_featured BOOLEAN DEFAULT false,
  views_count INTEGER DEFAULT 0,
  sales_count INTEGER DEFAULT 0,
  rating NUMERIC(3,2) DEFAULT 0,
  reviews_count INTEGER DEFAULT 0,
  tags TEXT[],
  origin_country TEXT,
  manufacturer TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Approved products are publicly viewable"
  ON products FOR SELECT USING (status = 'approved');

CREATE POLICY "Sellers can view their own products"
  ON products FOR SELECT USING (
    seller_id IN (SELECT id FROM seller_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "Sellers can insert products"
  ON products FOR INSERT WITH CHECK (
    seller_id IN (
      SELECT id FROM seller_profiles
      WHERE user_id = auth.uid() AND verification_status = 'approved'
    )
  );

CREATE POLICY "Sellers can update their own products"
  ON products FOR UPDATE USING (
    seller_id IN (SELECT id FROM seller_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins can manage all products"
  ON products FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- PRODUCT IMAGES TABLE
-- ============================================================
CREATE TABLE product_images (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  alt_text TEXT,
  is_primary BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Product images are publicly viewable" ON product_images FOR SELECT USING (true);
CREATE POLICY "Sellers can manage their product images" ON product_images FOR ALL USING (
  EXISTS (
    SELECT 1 FROM products p
    JOIN seller_profiles sp ON p.seller_id = sp.id
    WHERE p.id = product_id AND sp.user_id = auth.uid()
  )
);

-- ============================================================
-- CART TABLE
-- ============================================================
CREATE TABLE cart_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 1 CHECK (quantity > 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage their own cart" ON cart_items FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- ORDERS TABLE
-- ============================================================
CREATE TABLE orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_number TEXT UNIQUE NOT NULL DEFAULT ('ORD-' || UPPER(SUBSTRING(uuid_generate_v4()::TEXT, 1, 8))),
  buyer_id UUID REFERENCES profiles(id),
  total_amount NUMERIC(12,2) NOT NULL,
  shipping_address JSONB,
  status order_status DEFAULT 'pending',
  payment_method TEXT,
  payment_reference TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Buyers can view their own orders" ON orders FOR SELECT USING (buyer_id = auth.uid());
CREATE POLICY "Buyers can create orders" ON orders FOR INSERT WITH CHECK (buyer_id = auth.uid());
CREATE POLICY "Admins can view all orders" ON orders FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ============================================================
-- ORDER ITEMS TABLE
-- ============================================================
CREATE TABLE order_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  seller_id UUID REFERENCES seller_profiles(id),
  quantity INTEGER NOT NULL,
  unit_price NUMERIC(12,2) NOT NULL,
  total_price NUMERIC(12,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Order items viewable by buyer and seller" ON order_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM orders WHERE id = order_id AND buyer_id = auth.uid())
  OR seller_id IN (SELECT id FROM seller_profiles WHERE user_id = auth.uid())
);

-- ============================================================
-- NOTIFICATIONS TABLE
-- ============================================================
CREATE TABLE notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type notification_type DEFAULT 'general',
  reference_id UUID,
  reference_type TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update their own notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "System can insert notifications" ON notifications FOR INSERT WITH CHECK (true);

-- ============================================================
-- WISHLISTS TABLE
-- ============================================================
CREATE TABLE wishlists (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage their own wishlist" ON wishlists FOR ALL USING (user_id = auth.uid());

-- ============================================================
-- REVIEWS TABLE
-- ============================================================
CREATE TABLE reviews (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  order_id UUID REFERENCES orders(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  is_verified_purchase BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Reviews are publicly viewable" ON reviews FOR SELECT USING (true);
CREATE POLICY "Users can write reviews" ON reviews FOR INSERT WITH CHECK (user_id = auth.uid());

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('products', 'products', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('seller-documents', 'seller-documents', false);

-- Storage policies
CREATE POLICY "Avatars publicly readable" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload avatars" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'avatars' AND auth.uid()::TEXT = (STORAGE.FOLDERNAME(name))[1]
);
CREATE POLICY "Product images publicly readable" ON storage.objects FOR SELECT USING (bucket_id = 'products');
CREATE POLICY "Sellers can upload product images" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'products' AND auth.role() = 'authenticated'
);
CREATE POLICY "Sellers can upload documents" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'seller-documents' AND auth.role() = 'authenticated'
);
CREATE POLICY "Admins can view seller documents" ON storage.objects FOR SELECT USING (
  bucket_id = 'seller-documents' AND EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  )
);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_seller_profiles_updated_at BEFORE UPDATE ON seller_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Notify seller on product approval/rejection
CREATE OR REPLACE FUNCTION notify_product_review()
RETURNS TRIGGER AS $$
DECLARE
  seller_user_id UUID;
  notif_title TEXT;
  notif_body TEXT;
  notif_type notification_type;
BEGIN
  IF OLD.status != NEW.status AND NEW.status IN ('approved', 'rejected') THEN
    SELECT sp.user_id INTO seller_user_id
    FROM seller_profiles sp WHERE sp.id = NEW.seller_id;

    IF NEW.status = 'approved' THEN
      notif_title := 'Product Approved';
      notif_body := 'Your product "' || NEW.name || '" has been approved and is now live.';
      notif_type := 'product_approved';
    ELSE
      notif_title := 'Product Needs Revision';
      notif_body := 'Your product "' || NEW.name || '" was not approved. Reason: ' || COALESCE(NEW.rejection_reason, 'See details.');
      notif_type := 'product_rejected';
    END IF;

    INSERT INTO notifications (user_id, title, body, type, reference_id, reference_type)
    VALUES (seller_user_id, notif_title, notif_body, notif_type, NEW.id, 'product');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_product_reviewed
  AFTER UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION notify_product_review();

-- Notify seller on verification
CREATE OR REPLACE FUNCTION notify_seller_verification()
RETURNS TRIGGER AS $$
DECLARE
  notif_title TEXT;
  notif_body TEXT;
  notif_type notification_type;
BEGIN
  IF OLD.verification_status != NEW.verification_status THEN
    IF NEW.verification_status = 'approved' THEN
      notif_title := 'Seller Account Verified';
      notif_body := 'Congratulations! Your seller account has been verified. You can now upload products.';
      notif_type := 'seller_verified';

      -- Update role to seller
      UPDATE profiles SET role = 'seller' WHERE id = NEW.user_id;
    ELSE
      notif_title := 'Seller Verification Update';
      notif_body := 'Your seller application was not approved. Reason: ' || COALESCE(NEW.rejection_reason, 'Please contact support.');
      notif_type := 'seller_rejected';
    END IF;

    INSERT INTO notifications (user_id, title, body, type, reference_id, reference_type)
    VALUES (NEW.user_id, notif_title, notif_body, notif_type, NEW.id, 'seller_profile');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_seller_verified
  AFTER UPDATE ON seller_profiles
  FOR EACH ROW EXECUTE FUNCTION notify_seller_verification();
