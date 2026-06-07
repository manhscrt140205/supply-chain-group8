/*
# Supply Chain & Vendor Management Schema

## Summary
Creates the core tables for the ProcureAI supply chain management system.
This is a single-tenant application (no user auth), so all policies grant
access to both `anon` and `authenticated` roles using `USING (true)`.

## New Tables

### 1. `vendors`
Stores supplier / vendor records.
- `id` (uuid, PK)
- `vendor_code` (text, unique) — human-readable ID like "V001"
- `name` (text) — company name
- `category` (text) — e.g. Electronics, Logistics
- `contact` (text) — primary contact name
- `email` (text)
- `phone` (text)
- `country` (text)
- `status` (text) — Active | Under Review | Inactive
- `score` (integer 0-100) — overall vendor score
- `on_time_delivery` (integer 0-100) — on-time delivery %
- `quality_score` (integer 0-100) — quality %
- `response_time` (integer) — hours avg response
- `risk_score` (integer 0-100) — AI risk score
- `created_at` (timestamptz)

### 2. `purchase_orders`
Tracks procurement transactions.
- `id` (uuid, PK)
- `po_number` (text, unique) — e.g. "PO-2026-001"
- `vendor_id` (uuid, FK → vendors.id)
- `vendor_name` (text) — denormalised for display
- `order_date` (date)
- `due_date` (date)
- `total` (numeric 12,2)
- `items` (integer) — line-item count
- `status` (text) — Pending | Approved | Delivered | Overdue | Cancelled
- `created_at` (timestamptz)

### 3. `vendor_ratings`
Stores periodic performance snapshots for each vendor.
- `id` (uuid, PK)
- `vendor_id` (uuid, FK → vendors.id)
- `on_time` (integer)
- `quality` (integer)
- `response` (integer) — hours
- `recorded_at` (timestamptz)

## Security
- RLS enabled on all tables.
- Single-tenant: anon + authenticated can perform full CRUD.
  `USING (true)` is intentional — no auth required in this app.
*/

-- ─── vendors ──────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS vendors (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_code      text UNIQUE NOT NULL,
  name             text NOT NULL,
  category         text NOT NULL DEFAULT '',
  contact          text NOT NULL DEFAULT '',
  email            text NOT NULL DEFAULT '',
  phone            text NOT NULL DEFAULT '',
  country          text NOT NULL DEFAULT '',
  status           text NOT NULL DEFAULT 'Active',
  score            integer NOT NULL DEFAULT 75 CHECK (score BETWEEN 0 AND 100),
  on_time_delivery integer NOT NULL DEFAULT 80 CHECK (on_time_delivery BETWEEN 0 AND 100),
  quality_score    integer NOT NULL DEFAULT 80 CHECK (quality_score BETWEEN 0 AND 100),
  response_time    integer NOT NULL DEFAULT 48,
  risk_score       integer NOT NULL DEFAULT 30 CHECK (risk_score BETWEEN 0 AND 100),
  created_at       timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_vendors" ON vendors;
CREATE POLICY "anon_select_vendors" ON vendors FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_vendors" ON vendors;
CREATE POLICY "anon_insert_vendors" ON vendors FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_vendors" ON vendors;
CREATE POLICY "anon_update_vendors" ON vendors FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_vendors" ON vendors;
CREATE POLICY "anon_delete_vendors" ON vendors FOR DELETE
  TO anon, authenticated USING (true);

-- ─── purchase_orders ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS purchase_orders (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  po_number   text UNIQUE NOT NULL,
  vendor_id   uuid REFERENCES vendors(id) ON DELETE SET NULL,
  vendor_name text NOT NULL DEFAULT '',
  order_date  date NOT NULL,
  due_date    date NOT NULL,
  total       numeric(12,2) NOT NULL DEFAULT 0,
  items       integer NOT NULL DEFAULT 1,
  status      text NOT NULL DEFAULT 'Pending',
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_po_vendor_id ON purchase_orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_po_status    ON purchase_orders(status);
CREATE INDEX IF NOT EXISTS idx_po_due_date  ON purchase_orders(due_date);

ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_pos" ON purchase_orders;
CREATE POLICY "anon_select_pos" ON purchase_orders FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_pos" ON purchase_orders;
CREATE POLICY "anon_insert_pos" ON purchase_orders FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_pos" ON purchase_orders;
CREATE POLICY "anon_update_pos" ON purchase_orders FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_pos" ON purchase_orders;
CREATE POLICY "anon_delete_pos" ON purchase_orders FOR DELETE
  TO anon, authenticated USING (true);

-- ─── vendor_ratings ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS vendor_ratings (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id   uuid NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
  on_time     integer NOT NULL DEFAULT 80 CHECK (on_time BETWEEN 0 AND 100),
  quality     integer NOT NULL DEFAULT 80 CHECK (quality BETWEEN 0 AND 100),
  response    integer NOT NULL DEFAULT 48,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ratings_vendor_id ON vendor_ratings(vendor_id);

ALTER TABLE vendor_ratings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_ratings" ON vendor_ratings;
CREATE POLICY "anon_select_ratings" ON vendor_ratings FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_ratings" ON vendor_ratings;
CREATE POLICY "anon_insert_ratings" ON vendor_ratings FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_ratings" ON vendor_ratings;
CREATE POLICY "anon_update_ratings" ON vendor_ratings FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_ratings" ON vendor_ratings;
CREATE POLICY "anon_delete_ratings" ON vendor_ratings FOR DELETE
  TO anon, authenticated USING (true);
