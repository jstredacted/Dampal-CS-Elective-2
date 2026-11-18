-- Sole Street final exam: database schema, functions, triggers, RLS, storage.
-- Safe to run more than once. Run it in the Supabase SQL Editor (or CLI).

-- ============================================================
-- 1. Tables
-- ============================================================

-- Older runs of this script used roles.name and profiles.first_name/last_name.
-- Rename them so the columns match the course schema.
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'roles' and column_name = 'name') then
    alter table public.roles rename column name to role;
  end if;
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'profiles' and column_name = 'first_name') then
    alter table public.profiles rename column first_name to firstname;
  end if;
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'profiles' and column_name = 'last_name') then
    alter table public.profiles rename column last_name to lastname;
  end if;
end;
$$;

create table if not exists public.roles (
  id bigint generated always as identity primary key,
  role varchar not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- The user who created this role (null for the built-in roles).
  encoded_by uuid references auth.users (id) on delete set null
);

alter table public.roles alter column role type varchar;

insert into public.roles (role) values ('admin'), ('customer')
on conflict (role) do nothing;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  firstname text,
  lastname text,
  role_id bigint not null references public.roles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists email text;

-- categories and products already exist from the earlier activities.
alter table public.categories
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.products
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.orders (
  id bigint generated always as identity primary key,
  -- Points to profiles (whose id is the auth user id) so the admin order
  -- list can show the customer's name.
  user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'done'
    check (status in ('done', 'shipped', 'delivered', 'cancelled')),
  total numeric not null check (total >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id bigint generated always as identity primary key,
  order_id bigint not null references public.orders (id) on delete cascade,
  -- Becomes null if the product is deleted; the snapshot columns below keep
  -- the order history readable.
  product_id bigint references public.products (id) on delete set null,
  product_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric not null check (unit_price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists orders_user_id_idx on public.orders (user_id);
create index if not exists order_items_order_id_idx on public.order_items (order_id);

-- ============================================================
-- 2. Functions and triggers
-- ============================================================

-- Keeps updated_at current on every update.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array['roles', 'profiles', 'categories', 'products', 'orders', 'order_items'] loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format(
      'create trigger set_updated_at before update on public.%I
         for each row execute function public.set_updated_at()', t);
  end loop;
end;
$$;

-- Creates a profile for every new account. New accounts are always customers.
-- Email sign-up sends first_name/last_name metadata; Google sends given_name/family_name.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  full_name text := coalesce(meta ->> 'full_name', meta ->> 'name', '');
begin
  insert into public.profiles (id, email, firstname, lastname, role_id)
  values (
    new.id,
    new.email,
    coalesce(meta ->> 'first_name', meta ->> 'given_name', split_part(full_name, ' ', 1)),
    coalesce(meta ->> 'last_name', meta ->> 'family_name',
             nullif(substr(full_name, length(split_part(full_name, ' ', 1)) + 2), '')),
    (select id from public.roles where role = 'customer')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Accounts created before this trigger existed also get a customer profile.
insert into public.profiles (id, email, firstname, lastname, role_id)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data ->> 'first_name', split_part(coalesce(u.raw_user_meta_data ->> 'full_name', u.raw_user_meta_data ->> 'name', ''), ' ', 1)),
  u.raw_user_meta_data ->> 'last_name',
  (select id from public.roles where role = 'customer')
from auth.users u
on conflict (id) do nothing;

update public.profiles p
set email = u.email
from auth.users u
where u.id = p.id and p.email is distinct from u.email;

-- True when the signed-in user's profile has the admin role. security definer
-- lets policies call it without being blocked by the profiles policies.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    join public.roles r on r.id = p.role_id
    where p.id = auth.uid() and r.role = 'admin'
  );
$$;

-- Checkout. Saves one order and all its items, and lowers stock, in a single
-- transaction: if any step raises an error, nothing is saved.
-- The app sends only product ids and quantities; names, prices, and stock
-- are read from the products table here.
create or replace function public.place_order(p_items jsonb)
returns table (order_id bigint, total numeric)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_order_id bigint;
  v_total numeric := 0;
  line record;
  prod record;
begin
  if v_user is null then
    raise exception 'You must be signed in to place an order.' using errcode = '42501';
  end if;
  if public.is_admin() then
    raise exception 'Admin accounts cannot place orders.' using errcode = '42501';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Your cart is empty.' using errcode = '22023';
  end if;

  -- Same product twice in the request counts as one line. Rows are locked in
  -- id order (FOR UPDATE) so two checkouts cannot both buy the last pair.
  for line in
    select (e ->> 'product_id')::bigint as product_id, sum((e ->> 'quantity')::int) as quantity
    from jsonb_array_elements(p_items) e
    group by 1
    order by 1
  loop
    if line.quantity is null or line.quantity <= 0 then
      raise exception 'Quantities must be at least 1.' using errcode = '22023';
    end if;

    select p.id, p.name, p.price, p.stock into prod
    from public.products p
    where p.id = line.product_id
    for update;

    if not found then
      raise exception 'A product in your cart is no longer available.' using errcode = 'P0002';
    end if;
    if prod.stock < line.quantity then
      raise exception 'Only % left of %.', prod.stock, prod.name using errcode = '23514';
    end if;

    v_total := v_total + prod.price * line.quantity;
  end loop;

  insert into public.orders (user_id, status, total)
  values (v_user, 'done', v_total)
  returning id into v_order_id;

  insert into public.order_items (order_id, product_id, product_name, quantity, unit_price)
  select v_order_id, p.id, p.name, l.quantity, p.price
  from (
    select (e ->> 'product_id')::bigint as product_id, sum((e ->> 'quantity')::int) as quantity
    from jsonb_array_elements(p_items) e
    group by 1
  ) l
  join public.products p on p.id = l.product_id;

  update public.products p
  set stock = p.stock - l.quantity
  from (
    select (e ->> 'product_id')::bigint as product_id, sum((e ->> 'quantity')::int) as quantity
    from jsonb_array_elements(p_items) e
    group by 1
  ) l
  where p.id = l.product_id;

  return query select v_order_id, v_total;
end;
$$;

revoke execute on function public.place_order(jsonb) from public, anon;
grant execute on function public.place_order(jsonb) to authenticated;
revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- ============================================================
-- 3. Table privileges (what each column-level action is allowed at all)
-- ============================================================

-- Signed-out visitors (anon) get nothing.
revoke all on public.roles, public.profiles, public.categories, public.products,
  public.orders, public.order_items from anon;

grant select on public.roles, public.profiles, public.categories, public.products,
  public.orders, public.order_items to authenticated;
grant insert, update, delete on public.categories, public.products to authenticated;

-- Customers may change their own name, never their role (or email, which
-- comes from their login).
revoke insert, update, delete on public.profiles from authenticated;
grant update (firstname, lastname) on public.profiles to authenticated;

-- Orders are only created by place_order; admins may change only the status.
revoke insert, update, delete on public.orders, public.order_items, public.roles from authenticated;
grant update (status) on public.orders to authenticated;

-- ============================================================
-- 4. Row Level Security policies
-- ============================================================

alter table public.roles enable row level security;
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- Old activity policies allowed signed-out visitors to change products.
drop policy if exists "Anyone can read categories" on public.categories;
drop policy if exists "Anyone can read products" on public.products;
drop policy if exists "Anyone can add products" on public.products;
drop policy if exists "Anyone can update products" on public.products;
drop policy if exists "Anyone can delete products" on public.products;

-- profiles
drop policy if exists "Users read own profile, admins read all" on public.profiles;
create policy "Users read own profile, admins read all" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- roles
drop policy if exists "Signed-in users read roles" on public.roles;
create policy "Signed-in users read roles" on public.roles
  for select to authenticated
  using (true);

-- categories
drop policy if exists "Signed-in users read categories" on public.categories;
create policy "Signed-in users read categories" on public.categories
  for select to authenticated using (true);

drop policy if exists "Admins add categories" on public.categories;
create policy "Admins add categories" on public.categories
  for insert to authenticated with check ((select public.is_admin()));

drop policy if exists "Admins edit categories" on public.categories;
create policy "Admins edit categories" on public.categories
  for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

drop policy if exists "Admins delete categories" on public.categories;
create policy "Admins delete categories" on public.categories
  for delete to authenticated using ((select public.is_admin()));

-- products
drop policy if exists "Signed-in users read products" on public.products;
create policy "Signed-in users read products" on public.products
  for select to authenticated using (true);

drop policy if exists "Admins add products" on public.products;
create policy "Admins add products" on public.products
  for insert to authenticated with check ((select public.is_admin()));

drop policy if exists "Admins edit products" on public.products;
create policy "Admins edit products" on public.products
  for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

drop policy if exists "Admins delete products" on public.products;
create policy "Admins delete products" on public.products
  for delete to authenticated using ((select public.is_admin()));

-- orders
drop policy if exists "Customers read own orders, admins read all" on public.orders;
create policy "Customers read own orders, admins read all" on public.orders
  for select to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "Admins update order status" on public.orders;
create policy "Admins update order status" on public.orders
  for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- order_items
drop policy if exists "Customers read own order items, admins read all" on public.order_items;
create policy "Customers read own order items, admins read all" on public.order_items
  for select to authenticated
  using (
    (select public.is_admin())
    or exists (
      select 1 from public.orders o
      where o.id = order_items.order_id and o.user_id = (select auth.uid())
    )
  );

-- ============================================================
-- 5. Storage for product images
-- ============================================================

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

drop policy if exists "Signed-in users read product images" on storage.objects;
create policy "Signed-in users read product images" on storage.objects
  for select to authenticated using (bucket_id = 'product-images');

drop policy if exists "Admins upload product images" on storage.objects;
create policy "Admins upload product images" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'product-images' and (select public.is_admin()));

drop policy if exists "Admins replace product images" on storage.objects;
create policy "Admins replace product images" on storage.objects
  for update to authenticated
  using (bucket_id = 'product-images' and (select public.is_admin()));

drop policy if exists "Admins delete product images" on storage.objects;
create policy "Admins delete product images" on storage.objects
  for delete to authenticated
  using (bucket_id = 'product-images' and (select public.is_admin()));
