# Veriqo — Verified Ecommerce App

A full-stack Flutter + Supabase ecommerce platform with seller verification and product approval workflows.

---

## Project Structure

```
lib/
├── main.dart
├── models/        models.dart          — All data models & enums
├── providers/     providers.dart       — Riverpod state providers
├── services/      supabase_service.dart — All Supabase API calls
├── utils/
│   ├── app_theme.dart                  — Colors, typography, spacing
│   └── app_router.dart                 — GoRouter navigation
├── widgets/       widgets.dart         — Shared UI components
└── screens/
    ├── shared/    splash_screen.dart
    ├── auth/      login, signup, seller_signup
    ├── buyer/     marketplace, product_detail, scan, cart, notifications, profile
    ├── seller/    dashboard, products, upload, notifications, profile
    └── admin/     dashboard, products, sellers, users
supabase/
└── migrations/    001_schema.sql       — Full Supabase schema
```

---

## Setup

### 1. Supabase Project

1. Create a project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run `supabase/migrations/001_schema.sql`
3. Copy your **Project URL** and **anon public key**

### 2. Configure the App

Open `lib/utils/app_theme.dart` and replace:

```dart
static const String supabaseUrl    = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run

```bash
flutter run
```

---

## User Roles & Flows

| Role   | Flow |
|--------|------|
| **Buyer** | Sign up → Browse marketplace → Scan products → Cart |
| **Seller** | Sign up (+ national ID upload) → Admin reviews → Verified → Upload products → Admin reviews products → Live |
| **Admin** | Hardcode role in DB → Review seller applications → Review products |

### Making an Admin

After your first sign-up, run this in Supabase SQL Editor:

```sql
UPDATE profiles SET role = 'admin' WHERE email = 'your@email.com';
```

---

## Key Features

- **Seller Verification** — National ID (front/back) + optional selfie uploaded to private Supabase Storage bucket. Admin views documents in-app and approves/rejects with reason.
- **Product Approval** — Every product goes through `pending_review → approved/rejected` before appearing in the marketplace. Sellers are notified automatically via DB triggers.
- **Grid Marketplace** — Products display in a 2-column grid with images, price, discount badge, and rating.
- **Bottom Navigation** — Buyer (Market · Scan · Alerts · Cart · Profile), Seller (Dashboard · Products · Upload · Alerts · Profile), Admin (Dashboard · Products · Sellers · Users).
- **Product Scanner** — Camera-based barcode/QR scanner for product origin verification.
- **Real-time Notifications** — DB triggers auto-insert notifications when products or sellers are approved/rejected.

---

## Dependencies

```yaml
supabase_flutter, flutter_riverpod, go_router, google_fonts,
cached_network_image, shimmer, image_picker, mobile_scanner,
file_picker, intl, timeago, uuid
```
