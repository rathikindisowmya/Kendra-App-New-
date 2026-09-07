-- ============================================================
-- KENDRA — All-in-one Supabase Migration and Repair Script
-- Run this in: Supabase Dashboard → SQL Editor → New query → Run
-- Safe to run multiple times (IF NOT EXISTS throughout).
-- Fixes: missing tables, missing columns, missing RLS policies,
--        and refreshes the PostgREST schema cache.
-- ============================================================

-- ── 1. Create tables if they don't exist yet ─────────────────────────────────

create table if not exists businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null, industry_type text default 'retail',
  owner_id uuid references auth.users(id) not null,
  phone text, email text, address text, gst_number text,
  created_at timestamptz default now()
);

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  business_id uuid references businesses(id) on delete cascade,
  full_name text, role text default 'owner',
  created_at timestamptz default now()
);

create table if not exists suppliers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  name text not null,
  contact_person text, email text, phone text, gst_number text, address text,
  payment_terms text default 'Net 30', rating numeric default 5.0,
  payment_status text default 'Current', supplied_products text, notes text,
  status text default 'active',
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists employees (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  name text not null,
  department text, role text, designation text, photo_url text,
  salary numeric default 0, attendance_pct numeric default 100,
  leave_balance int default 12, performance numeric default 0,
  notes text, status text default 'active', is_archived boolean default false,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  name text not null,
  email text, phone text, address text, last_purchase date,
  ltv numeric default 0, outstanding_balance numeric default 0,
  has_complaint boolean default false, followup_date date, is_vip boolean default false,
  notes text, status text default 'active', is_archived boolean default false,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  name text not null,
  image_url text, supplier_id uuid references suppliers(id) on delete set null,
  supplier text, stock int default 0, reorder_point int default 10,
  purchase_price numeric default 0, selling_price numeric default 0,
  warehouse_location text default 'Main Warehouse',
  notes text, status text default 'active', is_archived boolean default false,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists purchase_orders (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  po_number text, supplier_id uuid references suppliers(id) on delete set null,
  supplier text, product_id uuid references products(id) on delete set null,
  product_name text, quantity int default 0, unit_price numeric default 0,
  total_amount numeric default 0, status text default 'Draft',
  expected_date date, notes text,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists goods_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  po_id uuid references purchase_orders(id) on delete set null,
  product_id uuid references products(id) on delete set null,
  product_name text not null, supplier_name text,
  movement_type text default 'Goods Receipt',
  warehouse_location text default 'Main Warehouse',
  expected_qty int default 0, received_qty int default 0,
  rejected_qty int default 0, damaged_qty int default 0,
  delivery_status text default 'Received', notes text,
  movement_date timestamptz default now(), created_at timestamptz default now()
);

create table if not exists invoices (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  invoice_no text not null,
  customer_id uuid references customers(id) on delete set null,
  customer_name text not null, customer_email text,
  supplier_id uuid references suppliers(id) on delete set null, supplier_name text,
  items jsonb default '[]'::jsonb,
  subtotal numeric default 0, tax_pct numeric default 18,
  tax_amount numeric default 0, discount numeric default 0,
  amount numeric not null default 0, issue_date date default current_date, due_date date,
  payment_terms text default 'Net 30', status text default 'Draft', notes text,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists expenses (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  vendor text, amount numeric not null default 0, category text default 'Misc',
  expense_date date default current_date, source text default 'manual',
  notes text, status text default 'Approved',
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  title text not null, assignee text, due_date date,
  priority text default 'Medium', status text default 'To Do',
  notes text, is_archived boolean default false,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  name text not null, category text default 'Contracts',
  file_url text, notes text,
  created_at timestamptz default now()
);

create table if not exists import_history (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  file_name text not null, record_type text not null,
  imported_count int default 0, duplicate_count int default 0,
  error_count int default 0, status text default 'Completed', details text,
  created_at timestamptz default now()
);

create table if not exists activity_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  action text not null, module text not null, details text,
  created_at timestamptz default now()
);

-- ── 2. Add any missing columns to existing tables ────────────────────────────
alter table if exists products add column if not exists purchase_price    numeric     default 0;
alter table if exists products add column if not exists selling_price     numeric     default 0;
alter table if exists products add column if not exists reorder_point     int         default 10;
alter table if exists products add column if not exists image_url         text;
alter table if exists products add column if not exists supplier          text;
alter table if exists products add column if not exists warehouse_location text        default 'Main Warehouse';
alter table if exists products add column if not exists notes             text;
alter table if exists products add column if not exists status            text        default 'active';
alter table if exists products add column if not exists is_archived       boolean     default false;
alter table if exists products add column if not exists updated_at        timestamptz default now();
alter table if exists employees add column if not exists salary           numeric     default 0;
alter table if exists employees add column if not exists attendance_pct   numeric     default 100;
alter table if exists employees add column if not exists leave_balance    int         default 12;
alter table if exists employees add column if not exists performance      numeric     default 0;
alter table if exists employees add column if not exists designation      text;
alter table if exists employees add column if not exists photo_url        text;
alter table if exists employees add column if not exists notes            text;
alter table if exists employees add column if not exists status           text        default 'active';
alter table if exists employees add column if not exists is_archived      boolean     default false;
alter table if exists employees add column if not exists updated_at       timestamptz default now();
alter table if exists customers add column if not exists last_purchase       date;
alter table if exists customers add column if not exists ltv                 numeric default 0;
alter table if exists customers add column if not exists outstanding_balance numeric default 0;
alter table if exists customers add column if not exists has_complaint       boolean default false;
alter table if exists customers add column if not exists followup_date       date;
alter table if exists customers add column if not exists is_vip              boolean default false;
alter table if exists customers add column if not exists notes               text;
alter table if exists customers add column if not exists status              text    default 'active';
alter table if exists customers add column if not exists is_archived         boolean default false;
alter table if exists customers add column if not exists updated_at          timestamptz default now();
alter table if exists suppliers add column if not exists contact_person   text;
alter table if exists suppliers add column if not exists gst_number       text;
alter table if exists suppliers add column if not exists payment_terms    text    default 'Net 30';
alter table if exists suppliers add column if not exists rating           numeric default 5.0;
alter table if exists suppliers add column if not exists payment_status   text    default 'Current';
alter table if exists suppliers add column if not exists supplied_products text;
alter table if exists suppliers add column if not exists notes            text;
alter table if exists suppliers add column if not exists status           text    default 'active';
alter table if exists suppliers add column if not exists updated_at       timestamptz default now();
alter table if exists invoices add column if not exists customer_email  text;
alter table if exists invoices add column if not exists supplier_name   text;
alter table if exists invoices add column if not exists items           jsonb       default '[]'::jsonb;
alter table if exists invoices add column if not exists subtotal        numeric     default 0;
alter table if exists invoices add column if not exists tax_pct         numeric     default 18;
alter table if exists invoices add column if not exists tax_amount      numeric     default 0;
alter table if exists invoices add column if not exists discount        numeric     default 0;
alter table if exists invoices add column if not exists payment_terms   text        default 'Net 30';
alter table if exists invoices add column if not exists notes           text;
alter table if exists invoices add column if not exists updated_at      timestamptz default now();
alter table if exists expenses add column if not exists expense_date    date    default current_date;
alter table if exists expenses add column if not exists source          text    default 'manual';
alter table if exists expenses add column if not exists notes           text;
alter table if exists expenses add column if not exists status          text    default 'Approved';
alter table if exists expenses add column if not exists updated_at      timestamptz default now();

-- ── 3. kendra_meta JSONB (stores extra imported fields per row) ───────────────
alter table if exists employees       add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists customers       add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists products        add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists suppliers       add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists goods_movements add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists invoices        add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists expenses        add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists tasks           add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists documents       add column if not exists kendra_meta jsonb default '{}'::jsonb;

-- ── 4. Enable Row-Level Security ─────────────────────────────────────────────
alter table if exists businesses      enable row level security;
alter table if exists profiles        enable row level security;
alter table if exists suppliers       enable row level security;
alter table if exists employees       enable row level security;
alter table if exists customers       enable row level security;
alter table if exists products        enable row level security;
alter table if exists purchase_orders enable row level security;
alter table if exists goods_movements enable row level security;
alter table if exists invoices        enable row level security;
alter table if exists expenses        enable row level security;
alter table if exists tasks           enable row level security;
alter table if exists documents       enable row level security;
alter table if exists import_history  enable row level security;
alter table if exists activity_logs   enable row level security;

-- ── 5. RLS policies (skipped if already exist) ────────────────────────────────
do $$ begin
  if not exists (select 1 from pg_policies where policyname='businesses_select_own' and tablename='businesses') then
    create policy "businesses_select_own" on businesses for select using (owner_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where policyname='businesses_update_own' and tablename='businesses') then
    create policy "businesses_update_own" on businesses for update using (owner_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where policyname='businesses_insert_own' and tablename='businesses') then
    create policy "businesses_insert_own" on businesses for insert with check (owner_id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where policyname='profiles_select_own' and tablename='profiles') then
    create policy "profiles_select_own" on profiles for select using (id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where policyname='profiles_insert_own' and tablename='profiles') then
    create policy "profiles_insert_own" on profiles for insert with check (id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where policyname='profiles_update_own' and tablename='profiles') then
    create policy "profiles_update_own" on profiles for update using (id = auth.uid());
  end if;
  if not exists (select 1 from pg_policies where policyname='suppliers_all' and tablename='suppliers') then
    create policy "suppliers_all" on suppliers for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='employees_all' and tablename='employees') then
    create policy "employees_all" on employees for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='customers_all' and tablename='customers') then
    create policy "customers_all" on customers for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='products_all' and tablename='products') then
    create policy "products_all" on products for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='invoices_all' and tablename='invoices') then
    create policy "invoices_all" on invoices for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='expenses_all' and tablename='expenses') then
    create policy "expenses_all" on expenses for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='tasks_all' and tablename='tasks') then
    create policy "tasks_all" on tasks for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='documents_all' and tablename='documents') then
    create policy "documents_all" on documents for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='import_history_all' and tablename='import_history') then
    create policy "import_history_all" on import_history for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='goods_movements_all' and tablename='goods_movements') then
    create policy "goods_movements_all" on goods_movements for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='purchase_orders_all' and tablename='purchase_orders') then
    create policy "purchase_orders_all" on purchase_orders for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where policyname='activity_logs_all' and tablename='activity_logs') then
    create policy "activity_logs_all" on activity_logs for all
      using (business_id=(select business_id from profiles where id=auth.uid()))
      with check (business_id=(select business_id from profiles where id=auth.uid()));
  end if;
end $$;

-- ── 6. Reload PostgREST schema cache ─────────────────────────────────────────
notify pgrst, 'reload schema';

