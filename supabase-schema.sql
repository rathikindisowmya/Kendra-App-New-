-- ============================================================
-- KENDRA — Enterprise Business Operating System Supabase Schema
-- Run this in your Supabase project's SQL Editor
-- (Dashboard → SQL Editor → New query → paste all of this → Run)
-- ============================================================

-- 1. Businesses: one row per signed-up company
create table if not exists businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  industry_type text default 'retail',
  owner_id uuid references auth.users(id) not null,
  phone text,
  email text,
  address text,
  gst_number text,
  created_at timestamptz default now()
);

-- 2. Profiles: links an auth user to a business
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  business_id uuid references businesses(id) on delete cascade,
  full_name text,
  role text default 'owner',
  created_at timestamptz default now()
);

-- 3. Suppliers (NEW)
create table if not exists suppliers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  name text not null,
  contact_person text,
  email text,
  phone text,
  gst_number text,
  address text,
  payment_terms text default 'Net 30',
  rating numeric default 5.0,
  payment_status text default 'Current', -- Current | Overdue | Pending
  supplied_products text,
  notes text,
  status text default 'active', -- active | archived
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 4. Employees
create table if not exists employees (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  name text not null,
  department text,
  role text,
  designation text,
  photo_url text,
  salary numeric default 0,
  attendance_pct numeric default 100,
  leave_balance int default 12,
  performance numeric default 0,
  notes text,
  status text default 'active', -- active | on_leave | inactive
  is_archived boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 5. Customers / CRM
create table if not exists customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  name text not null,
  email text,
  phone text,
  address text,
  last_purchase date,
  ltv numeric default 0,
  outstanding_balance numeric default 0,
  has_complaint boolean default false,
  followup_date date,
  is_vip boolean default false,
  notes text,
  status text default 'active', -- active | archived
  is_archived boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 6. Products / Inventory
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  name text not null,
  image_url text,
  supplier_id uuid references suppliers(id) on delete set null,
  supplier text,
  stock int default 0,
  reorder_point int default 10,
  purchase_price numeric default 0,
  selling_price numeric default 0,
  warehouse_location text default 'Main Warehouse',
  notes text,
  status text default 'active', -- active | archived
  is_archived boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 7. Purchase orders
create table if not exists purchase_orders (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  po_number text,
  supplier_id uuid references suppliers(id) on delete set null,
  supplier text,
  product_id uuid references products(id) on delete set null,
  product_name text,
  quantity int default 0,
  unit_price numeric default 0,
  total_amount numeric default 0,
  status text default 'Draft', -- Draft | Ordered | Received | Partially Received | Cancelled
  expected_date date,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 8. Goods Tracking / Movement Logs (NEW)
create table if not exists goods_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  po_id uuid references purchase_orders(id) on delete set null,
  product_id uuid references products(id) on delete set null,
  product_name text not null,
  supplier_name text,
  movement_type text default 'Goods Receipt', -- Goods Receipt | Goods Issue | Transfer | Return | Damage
  warehouse_location text default 'Main Warehouse',
  expected_qty int default 0,
  received_qty int default 0,
  rejected_qty int default 0,
  damaged_qty int default 0,
  delivery_status text default 'Received', -- In Transit | Received | Inspected | Rejected | Completed
  notes text,
  movement_date timestamptz default now(),
  created_at timestamptz default now()
);

-- 9. Invoices
create table if not exists invoices (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  invoice_no text not null,
  customer_id uuid references customers(id) on delete set null,
  customer_name text not null,
  customer_email text,
  supplier_id uuid references suppliers(id) on delete set null,
  supplier_name text,
  items jsonb default '[]'::jsonb,
  subtotal numeric default 0,
  tax_pct numeric default 18,
  tax_amount numeric default 0,
  discount numeric default 0,
  amount numeric not null default 0,
  issue_date date default current_date,
  due_date date,
  payment_terms text default 'Net 30',
  status text default 'Draft', -- Draft | Sent | Viewed | Paid | Cancelled
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 10. Expenses
create table if not exists expenses (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  vendor text,
  amount numeric not null default 0,
  category text default 'Misc',
  expense_date date default current_date,
  source text default 'manual', -- manual | ocr | import
  notes text,
  status text default 'Approved',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 11. Tasks (Kanban)
create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  title text not null,
  assignee text,
  due_date date,
  priority text default 'Medium', -- Low | Medium | High
  status text default 'To Do', -- To Do | In Progress | Review | Done
  notes text,
  is_archived boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 12. Documents
create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  name text not null,
  category text default 'Contracts',
  file_url text,
  notes text,
  created_at timestamptz default now()
);

-- 13. Import History (NEW)
create table if not exists import_history (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  file_name text not null,
  record_type text not null, -- employees | customers | products | suppliers | expenses | purchase_orders
  imported_count int default 0,
  duplicate_count int default 0,
  error_count int default 0,
  status text default 'Completed',
  details text,
  created_at timestamptz default now()
);

-- 14. Activity Logs (NEW)
create table if not exists activity_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade not null,
  action text not null,
  module text not null,
  details text,
  created_at timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

alter table businesses enable row level security;
alter table profiles enable row level security;
alter table suppliers enable row level security;
alter table employees enable row level security;
alter table customers enable row level security;
alter table products enable row level security;
alter table purchase_orders enable row level security;
alter table goods_movements enable row level security;
alter table invoices enable row level security;
alter table expenses enable row level security;
alter table tasks enable row level security;
alter table documents enable row level security;
alter table import_history enable row level security;
alter table activity_logs enable row level security;

-- Businesses
create policy "businesses_select_own" on businesses for select using (owner_id = auth.uid());
create policy "businesses_update_own" on businesses for update using (owner_id = auth.uid());
create policy "businesses_insert_own" on businesses for insert with check (owner_id = auth.uid());

-- Profiles
create policy "profiles_select_own" on profiles for select using (id = auth.uid());
create policy "profiles_insert_own" on profiles for insert with check (id = auth.uid());
create policy "profiles_update_own" on profiles for update using (id = auth.uid());

-- Universal Business Policy Helper
create policy "suppliers_all" on suppliers for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "employees_all" on employees for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "customers_all" on customers for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "products_all" on products for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "purchase_orders_all" on purchase_orders for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "goods_movements_all" on goods_movements for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "invoices_all" on invoices for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "expenses_all" on expenses for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "tasks_all" on tasks for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "documents_all" on documents for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "import_history_all" on import_history for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));

create policy "activity_logs_all" on activity_logs for all
  using (business_id = (select business_id from profiles where id = auth.uid()))
  with check (business_id = (select business_id from profiles where id = auth.uid()));
