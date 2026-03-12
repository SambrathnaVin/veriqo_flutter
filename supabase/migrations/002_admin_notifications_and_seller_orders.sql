-- ============================================================
-- VERIQO - Migration 002
-- Admin notifications + seller order policies
-- Run after 001_schema.sql in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- ADMIN NOTIFICATIONS
-- Notify all admins when a new seller applies
-- ============================================================
CREATE OR REPLACE FUNCTION notify_admins_new_seller()
RETURNS TRIGGER AS $$
DECLARE
  admin_id UUID;
  seller_name TEXT;
BEGIN
  -- Get business name
  seller_name := NEW.business_name;

  -- Insert notification for every admin
  FOR admin_id IN
    SELECT id FROM profiles WHERE role = 'admin'
  LOOP
    INSERT INTO notifications (user_id, title, body, type, reference_id, reference_type)
    VALUES (
      admin_id,
      'New Seller Application',
      seller_name || ' has submitted a seller application and is awaiting verification.',
      'general',
      NEW.id,
      'seller_profile'
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_new_seller_application
  AFTER INSERT ON seller_profiles
  FOR EACH ROW EXECUTE FUNCTION notify_admins_new_seller();

-- ============================================================
-- ADMIN NOTIFICATIONS
-- Notify all admins when a new product is submitted for review
-- ============================================================
CREATE OR REPLACE FUNCTION notify_admins_new_product()
RETURNS TRIGGER AS $$
DECLARE
  admin_id UUID;
  business_name TEXT;
BEGIN
  -- Only fire on new pending_review products, or status change TO pending_review
  IF (TG_OP = 'INSERT' AND NEW.status = 'pending_review')
     OR (TG_OP = 'UPDATE' AND OLD.status != 'pending_review' AND NEW.status = 'pending_review')
  THEN
    SELECT sp.business_name INTO business_name
    FROM seller_profiles sp WHERE sp.id = NEW.seller_id;

    FOR admin_id IN
      SELECT id FROM profiles WHERE role = 'admin'
    LOOP
      INSERT INTO notifications (user_id, title, body, type, reference_id, reference_type)
      VALUES (
        admin_id,
        'New Product Awaiting Review',
        '"' || NEW.name || '" by ' || COALESCE(business_name, 'a seller') || ' is pending review.',
        'general',
        NEW.id,
        'product'
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_product_submitted_for_review
  AFTER INSERT OR UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION notify_admins_new_product();

-- ============================================================
-- SELLER ORDER POLICIES
-- Allow sellers to see and update orders that contain their products
-- ============================================================

-- Sellers can update order status for orders containing their products
CREATE POLICY "Sellers can update orders for their products"
  ON orders FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM order_items oi
      JOIN seller_profiles sp ON oi.seller_id = sp.id
      WHERE oi.order_id = orders.id AND sp.user_id = auth.uid()
    )
  );

-- Sellers can view orders containing their products
CREATE POLICY "Sellers can view orders for their products"
  ON orders FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM order_items oi
      JOIN seller_profiles sp ON oi.seller_id = sp.id
      WHERE oi.order_id = orders.id AND sp.user_id = auth.uid()
    )
  );

-- ============================================================
-- ORDERS: update updated_at trigger
-- ============================================================
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
