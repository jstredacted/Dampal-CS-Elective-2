# Sole Street

A Flutter e-commerce app for sneakers, built for the Mobile Applications
Development (Flutter) final exam. Admins manage the product catalog;
customers browse, fill a cart, check out, and review their past orders.

| Area | Used |
|---|---|
| State management | Riverpod (`flutter_riverpod`) |
| Backend | Supabase: Auth, Postgres, Row Level Security |
| Sign-in methods | Email and password, Google |
| Image storage | Supabase Storage (`product-images` bucket) |

## Features

**Everyone**
- Sign up and log in with email and password, or with Google.
- New accounts always start as customers (created by a database trigger).

**Customers**
- Browse products with search, category and price filters, and pagination.
- Cart: add, change quantity, remove; running total and item count.
  Quantities can't go above stock, and out-of-stock products can't be added.
- The cart stays in app state across screens and is emptied after a
  successful order and on logout.
- Checkout shows a confirmation with the order number and total.
- Order history lists only the customer's own orders, newest first, with
  status, date, total, and items.

**Admins**
- Add and edit products (name, description, price, stock, category, image).
  The edit form is pre-filled; deleting asks for confirmation and names the
  product.
- Validation: name is required, price is a number of zero or more, stock is a
  whole number of zero or more.
- Manage categories.
- See every customer's orders and change an order's status.
- Admin controls are not shown to customers, and the database rejects them
  anyway (see Row Level Security below).

## Project structure

Screens call providers, providers call services, and services are the only
code that talks to Supabase.

```text
lib/
├── main.dart        # Supabase.initialize, ProviderScope, theme, AuthGate
├── models/          # Product, Category, Profile, CartItem, Order, filters
├── services/        # Supabase calls: auth, profiles, products, categories,
│                    #   orders (place_order), storage (image upload)
├── providers/       # Riverpod providers and notifiers (user, cart, orders, ...)
├── pages/           # Screens: login, sign-up, products, product form,
│                    #   categories, cart, confirmation, order history, admin orders
├── widgets/         # Reusable widgets: product card, order card, filters, ...
├── theme/           # App-wide colors and typography
└── utils/           # Formatting and error messages
supabase/
└── final_exam_setup.sql   # Schema, functions, triggers, RLS, storage
test/                      # Widget tests with fake services
```

## Database

`supabase/final_exam_setup.sql` creates everything the app needs. It is safe
to run more than once.

**Tables:** `roles`, `profiles`, `categories`, `products`, `orders`,
`order_items`.

**Functions and triggers**
- `handle_new_user()` (trigger `on_auth_user_created` on `auth.users`):
  creates a customer profile with the user's email and name.
- `is_admin()`: true when the signed-in user's role is `admin`; used by the
  policies.
- `place_order(p_items)`: checkout in one transaction. It reads prices, names,
  and stock from the database (the app only sends product ids and quantities),
  saves the order and its items, and lowers stock. If any step fails, nothing
  is saved. Each order item keeps a snapshot of the product name and unit
  price.
- `set_updated_at()`: keeps `updated_at` current on every update.

**Row Level Security** (enabled on every table)

| Table | Signed out | Customer | Admin |
|---|---|---|---|
| profiles | No access | Read and update own row, never the role | Read all |
| roles | No access | Read | Read |
| categories | No access | Read | Read, add, edit, delete |
| products | No access | Read | Read, add, edit, delete |
| orders | No access | Read own orders | Read all, update status |
| order_items | No access | Read items of own orders | Read all |

Only admins can upload, replace, or delete files in the `product-images`
bucket.

## Setup

1. **Database:** open the Supabase SQL Editor and run
   `supabase/final_exam_setup.sql`.
2. **Google sign-in:**
   - In Google Cloud, create an OAuth client (Web application). Add your app's
     address (for example `http://localhost:3000`) as an authorized JavaScript
     origin and `https://<project-ref>.supabase.co/auth/v1/callback` as an
     authorized redirect URI.
   - In Supabase, go to *Authentication → Sign In / Providers → Google*,
     enable it, and paste in the client ID and secret.
   - In *Authentication → URL Configuration*, add the app's address to
     **Redirect URLs**.
3. **Make an admin:** sign up, then run this in the SQL Editor:

   ```sql
   update public.profiles
   set role_id = (select id from public.roles where role = 'admin')
   where id = (select id from auth.users where email = '<admin email>');
   ```

The Supabase URL and publishable key are set in `lib/main.dart`.

## Running

```bash
flutter pub get
flutter run -d chrome --web-port 3000
```

Use the same port you added to the Google and Supabase redirect settings.
Google sign-in returns to the address the app is running on, so test it on
the web.

```bash
flutter analyze
flutter test
```
