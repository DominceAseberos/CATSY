-- ============================================================
-- CUTshier — Fixed & Complete Database Schema
-- Version: 2.0 (Reviewed against SRS + Dev Guide v1.2)
-- ============================================================
-- HOW TO READ THE COMMENTS:
--   [FIXED]   — was in original schema but had a bug or wrong column
--   [ADDED]   — missing from original schema, added now
--   [REMOVED] — existed in original but removed because it conflicts with SRS
--   [OK]      — unchanged, was already correct
-- ============================================================


-- ============================================================
-- SECTION 1: USER ACCOUNTS & ROLES
-- ============================================================

-- [OK] Core auth table — managed by Supabase Auth
-- user_profiles extends auth.users with role and profile info
CREATE TABLE public.user_profiles (
  id                uuid          NOT NULL,                          -- matches auth.users.id
  email             text          NOT NULL,
  role              text          NOT NULL DEFAULT 'customer'
                                  CHECK (role = ANY (ARRAY['admin','staff','customer'])),
  first_name        text,
  last_name         text,
  contact           text,
  account_id        text          UNIQUE,                            -- human-readable loyalty ID (e.g. CUTSY-00123)
  is_active         boolean       DEFAULT true,
  created_at        timestamp with time zone DEFAULT now(),
  last_login        timestamp with time zone,
  last_updated      timestamp with time zone DEFAULT now(),
  CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT user_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

-- [FIXED] customers table was a DUPLICATE of user_profiles for registered customers.
-- RESOLUTION:
--   - Registered customers → user_profiles (role = 'customer') + qr_code column added there
--   - Guest reservations → inline fields on reservations table (first_name, last_name, phone, email)
--   - orders.customer_id now references user_profiles instead of a separate customers table
--   - The old public.customers table is REMOVED
--
-- [ADDED] qr_code column on user_profiles (was on old customers table)
-- [ADDED] excess_stamps column — tracks overflow stamps queued for next cycle (SRS Section 5)
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS qr_code      text UNIQUE,
  ADD COLUMN IF NOT EXISTS excess_stamps integer NOT NULL DEFAULT 0;
-- NOTE: If running fresh, include these columns in the CREATE TABLE above instead of ALTER.


-- ============================================================
-- SECTION 2: CAFE SETTINGS
-- ============================================================

-- [FIXED] restaurant_settings: removed available_tables (computed value, not stored)
-- available seat count is derived at query time from cafe_tables, not stored here
-- to avoid going out of sync with actual seat states.
CREATE TABLE public.restaurant_settings (
  id              integer   NOT NULL DEFAULT 1 CHECK (id = 1),     -- singleton row, only 1 row ever
  is_open         boolean   NOT NULL DEFAULT true,
  opening_time    time      NOT NULL DEFAULT '17:00:00',            -- default 5:00 PM per SRS
  closing_time    time      NOT NULL DEFAULT '00:00:00',            -- default 12:00 AM per SRS
  total_seats     integer   NOT NULL DEFAULT 10,                    -- renamed from total_tables for clarity
  updated_at      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT restaurant_settings_pkey PRIMARY KEY (id)
);

-- [REMOVED] time_slots table
-- Decision from Dev Guide v1.2: replace fixed slot system with opening_time + closing_time only.
-- Customers pick any time within operating hours using a time picker.
-- restaurant_settings.opening_time and closing_time handle this entirely.
-- DROP TABLE public.time_slots; -- include this if migrating from old schema


-- ============================================================
-- SECTION 3: PRODUCTS & CATEGORIES
-- ============================================================

-- [FIXED] categories: removed linked_product_id (circular FK back to products — wrong direction)
-- The correct direction is products.category_id → categories, not the other way around.
CREATE TABLE public.categories (
  category_id   integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  name          text    NOT NULL UNIQUE,
  description   text,
  created_at    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT categories_pkey PRIMARY KEY (category_id)
);

-- [OK] products table — already mostly correct
-- product_is_reward column: this duplicates reward_items table. Keep it as a denormalized flag
-- for fast queries (e.g. show reward toggle in product list without joining reward_items).
CREATE TABLE public.products (
  product_id          integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  category_id         integer,
  product_name        character varying NOT NULL,
  product_description text,                                          -- [ADDED] was missing
  product_price       numeric   NOT NULL CHECK (product_price >= 0),
  product_is_eligible boolean   NOT NULL DEFAULT false,              -- stamp eligible
  product_is_featured boolean   NOT NULL DEFAULT false,
  product_is_available boolean  NOT NULL DEFAULT true,
  product_is_reward   boolean   NOT NULL DEFAULT false,              -- reward item toggle
  product_created     timestamp with time zone NOT NULL DEFAULT now(),
  product_updated     timestamp with time zone NOT NULL DEFAULT now(), -- [ADDED]
  CONSTRAINT products_pkey PRIMARY KEY (product_id),
  CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(category_id)
);

-- [OK] reward_items — links rewards to existing products via FK (correct, not free-text)
CREATE TABLE public.reward_items (
  id          uuid    NOT NULL DEFAULT gen_random_uuid(),
  product_id  integer NOT NULL UNIQUE,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamp with time zone NOT NULL DEFAULT now(),
  updated_at  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT reward_items_pkey PRIMARY KEY (id),
  CONSTRAINT reward_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id)
);


-- ============================================================
-- SECTION 4: INVENTORY (RAW MATERIALS)
-- ============================================================

-- [OK] raw_materials_inventory — tracks ingredient-level stock
CREATE TABLE public.raw_materials_inventory (
  material_id       bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  material_name     character varying NOT NULL,
  material_unit     text    DEFAULT 'unit',
  material_stock    numeric DEFAULT 0,
  material_reorder_level numeric DEFAULT 0,
  cost_per_unit     numeric DEFAULT 0,
  material_updated  timestamp with time zone DEFAULT now(),
  CONSTRAINT raw_materials_inventory_pkey PRIMARY KEY (material_id)
);

-- [OK] product_recipe — maps products to raw material quantities
-- This enables recipe-based inventory deduction when an order item is added.
-- NOTE: This is an undocumented addition beyond the SRS but is architecturally sound.
CREATE TABLE public.product_recipe (
  recipe_id         bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  product_id        integer,
  material_id       bigint,
  quantity_required numeric NOT NULL,
  CONSTRAINT product_recipe_pkey PRIMARY KEY (recipe_id),
  CONSTRAINT product_recipe_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id),
  CONSTRAINT product_recipe_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.raw_materials_inventory(material_id)
);


-- ============================================================
-- SECTION 5: SEATS / TABLES
-- ============================================================

-- [FIXED] cafe_tables: removed 'cleaning' status — SRS only defines Available, Occupied, Reserved.
-- If cleaning is needed in the future, add it back, but keep consistent with SRS for now.
CREATE TABLE public.cafe_tables (
  id          uuid    NOT NULL DEFAULT gen_random_uuid(),
  label       text    NOT NULL,                                      -- e.g. "Table 1", "Window Seat A"
  capacity    integer NOT NULL DEFAULT 2,
  status      text    NOT NULL DEFAULT 'available'
              CHECK (status = ANY (ARRAY['available','occupied','reserved'])),
  created_at  timestamp with time zone NOT NULL DEFAULT now(),
  updated_at  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT cafe_tables_pkey PRIMARY KEY (id)
);


-- ============================================================
-- SECTION 6: RESERVATIONS
-- ============================================================

-- [FIXED] reservations:
--   - status: removed 'completed' — SRS only needs pending, confirmed, cancelled
--   - added: approved_by (staff who approved), cancelled_at, notes renamed to special_requests (kept)
--   - user_id nullable (good — guests don't have accounts) [OK]
--   - guest info columns (first_name, last_name, phone, email) serve both guests and logged-in users
CREATE TABLE public.reservations (
  id                uuid    NOT NULL DEFAULT gen_random_uuid(),
  user_id           uuid,                                            -- NULL for guest reservations
  first_name        text    NOT NULL,
  last_name         text    NOT NULL,
  phone             text    NOT NULL,
  email             text,
  reservation_time  timestamp with time zone NOT NULL,              -- full datetime, no fixed slot
  guest_count       integer NOT NULL CHECK (guest_count BETWEEN 1 AND 10),
  special_requests  text,
  status            text    DEFAULT 'pending'
                    CHECK (status = ANY (ARRAY['pending','confirmed','cancelled'])),
  approved_by       uuid,                                           -- [ADDED] staff who approved/declined
  cancelled_at      timestamp with time zone,                       -- [ADDED]
  created_at        timestamp with time zone DEFAULT now(),
  CONSTRAINT reservations_pkey PRIMARY KEY (id),
  CONSTRAINT reservations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id),
  CONSTRAINT reservations_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.user_profiles(id)
);


-- ============================================================
-- SECTION 7: ORDERS & TRANSACTIONS
-- ============================================================

-- [FIXED] orders table — significant changes:
--   REMOVED: table_id — SRS FR S3 explicitly says no table assignment for orders
--   FIXED:   customer_id now → user_profiles (was → old customers table)
--   FIXED:   status values corrected for POS context
--   ADDED:   order_type (dine-in | take-out) — required by FR S3
--   ADDED:   payment_timing (pay_now | pay_later) — required by FR S3/S5
--   ADDED:   payment_status (unpaid | paid | voided | refunded) — required for pay-later flow
--   ADDED:   receipt_number — for receipt issuance and refund lookup
--   ADDED:   refunded_at, refund_reason — for refund tracking (FR S7)
--   KEPT:    payment_method, amount_tendered, change_due [OK — already correct]
CREATE TABLE public.orders (
  id              uuid    NOT NULL DEFAULT gen_random_uuid(),
  receipt_number  text    UNIQUE,                                    -- [ADDED] human-readable receipt ref
  customer_id     uuid,                                              -- [FIXED] → user_profiles (nullable for guest walk-ins)
  created_by      uuid,                                             -- staff who created the order
  order_type      text    NOT NULL DEFAULT 'dine-in'
                  CHECK (order_type = ANY (ARRAY['dine-in','take-out'])),           -- [ADDED] FR S3
  payment_timing  text    NOT NULL DEFAULT 'pay_now'
                  CHECK (payment_timing = ANY (ARRAY['pay_now','pay_later'])),      -- [ADDED] FR S3/S5
  payment_status  text    NOT NULL DEFAULT 'unpaid'
                  CHECK (payment_status = ANY (ARRAY['unpaid','paid','voided','refunded'])), -- [ADDED]
  status          text    NOT NULL DEFAULT 'open'
                  CHECK (status = ANY (ARRAY['open','closed','voided'])),           -- [FIXED] POS-appropriate values
  total_amount    numeric NOT NULL DEFAULT 0,
  payment_method  text    CHECK (payment_method = ANY (ARRAY['Cash','GCash','Maya'])),
  amount_tendered numeric,
  change_due      numeric,
  notes           text,
  refunded_at     timestamp with time zone,                          -- [ADDED] FR S7
  refund_reason   text,                                              -- [ADDED] FR S7
  stamps_credited boolean NOT NULL DEFAULT false,                    -- [ADDED] track if stamps were awarded
  created_at      timestamp with time zone NOT NULL DEFAULT now(),
  updated_at      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT orders_pkey PRIMARY KEY (id),
  CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.user_profiles(id),
  CONSTRAINT orders_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.user_profiles(id)
);

-- [FIXED] order_items: added is_stamp_eligible snapshot
-- This is CRITICAL: products.product_is_eligible can change AFTER the order is placed.
-- We must snapshot eligibility at the time of order so stamp counting is always accurate.
CREATE TABLE public.order_items (
  id                  uuid    NOT NULL DEFAULT gen_random_uuid(),
  order_id            uuid    NOT NULL,
  product_id          integer,                                       -- nullable: product may be deleted later
  product_name        text    NOT NULL,                              -- snapshot of name at order time
  quantity            integer NOT NULL DEFAULT 1,
  unit_price          numeric NOT NULL,                              -- snapshot of price at order time
  subtotal            numeric NOT NULL,
  is_stamp_eligible   boolean NOT NULL DEFAULT false,                -- [ADDED] snapshot at order time
  notes               text,
  created_at          timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT order_items_pkey PRIMARY KEY (id),
  CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id),
  CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id)
);


-- ============================================================
-- SECTION 8: LOYALTY STAMPS & REWARDS
-- ============================================================

-- [OK] loyalty_stamps — individual stamp records
-- is_spent = true when stamps are consumed during a reward claim
CREATE TABLE public.loyalty_stamps (
  id          bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id     uuid    NOT NULL,
  order_id    uuid,                                                  -- [FIXED] changed to uuid to match orders.id
  is_spent    boolean NOT NULL DEFAULT false,
  reward_id   bigint,                                                -- set when these stamps were used in a claim
  created_at  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT loyalty_stamps_pkey PRIMARY KEY (id),
  CONSTRAINT loyalty_stamps_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id),
  CONSTRAINT fk_loyalty_stamps_reward_id FOREIGN KEY (reward_id) REFERENCES public.loyalty_rewards(id)
);

-- [FIXED] loyalty_rewards:
--   FIXED:   reward_item text → product_id integer FK (Dev Guide: must reference existing product)
--   FIXED:   redeemed_by_staff_id → user_profiles (was → auth.users — inconsistent)
--   ADDED:   expires_at (reward codes should have expiry)
CREATE TABLE public.loyalty_rewards (
  id                    bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id               uuid    NOT NULL,
  coupon_code           text    NOT NULL UNIQUE,                     -- unique text code for in-store redemption
  product_id            integer NOT NULL,                            -- [FIXED] was free-text reward_item
  status                text    NOT NULL DEFAULT 'active'
                        CHECK (status = ANY (ARRAY['active','claimed','expired'])),
  created_at            timestamp with time zone NOT NULL DEFAULT now(),
  expires_at            timestamp with time zone,                    -- [ADDED] single-use codes should expire
  claimed_at            timestamp with time zone,
  redeemed_by_staff_id  uuid,                                       -- [FIXED] → user_profiles
  CONSTRAINT loyalty_rewards_pkey PRIMARY KEY (id),
  CONSTRAINT loyalty_rewards_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id),
  CONSTRAINT loyalty_rewards_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id),
  CONSTRAINT loyalty_rewards_redeemed_by_staff_id_fkey FOREIGN KEY (redeemed_by_staff_id) REFERENCES public.user_profiles(id)
);

-- [ADDED] stamps_queue — server-side tracking of offline stamp scans (NFR 8, Dev Guide)
-- When staff scans QR while offline, the mobile app queues the scan locally.
-- On reconnect, it pushes pending scans here. Background job processes them.
CREATE TABLE public.stamps_queue (
  id          bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  customer_id uuid    NOT NULL,
  order_id    uuid    NOT NULL,
  qty         integer NOT NULL DEFAULT 1,
  scanned_at  timestamp with time zone NOT NULL DEFAULT now(),       -- when staff scanned offline
  synced_at   timestamp with time zone,                             -- when sync was processed
  is_synced   boolean NOT NULL DEFAULT false,
  created_by  uuid,                                                  -- staff who scanned
  CONSTRAINT stamps_queue_pkey PRIMARY KEY (id),
  CONSTRAINT stamps_queue_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.user_profiles(id),
  CONSTRAINT stamps_queue_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id),
  CONSTRAINT stamps_queue_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.user_profiles(id)
);


-- ============================================================
-- SECTION 9: NOTIFICATIONS
-- ============================================================

-- [ADDED] notifications — required by SRS FR A8 and Dev Guide 2.9
-- Stores notifications for admin (low-stock, reports, employee) and staff (reservation, no-show)
CREATE TABLE public.notifications (
  id          uuid    NOT NULL DEFAULT gen_random_uuid(),
  user_id     uuid    NOT NULL,                                      -- recipient (admin or staff)
  type        text    NOT NULL
              CHECK (type = ANY (ARRAY[
                'low_stock',
                'reservation_approved',
                'reservation_declined',
                'reservation_cancelled',
                'no_show_warning',
                'refund_processed',
                'sync_complete',
                'stamp_pending',
                'ml_restock_alert'
              ])),
  title       text    NOT NULL,
  message     text    NOT NULL,
  entity_type text,                                                  -- e.g. 'order', 'reservation', 'product'
  entity_id   text,                                                  -- ID of the related entity
  is_read     boolean NOT NULL DEFAULT false,
  created_at  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);


-- ============================================================
-- SECTION 10: CMS
-- ============================================================

-- [OK] cms_content — covers banners, announcements, promos
CREATE TABLE public.cms_content (
  id          uuid    NOT NULL DEFAULT gen_random_uuid(),
  type        text    NOT NULL
              CHECK (type = ANY (ARRAY['banner','announcement','promo'])),
  title       text    NOT NULL,
  body        text,
  image_url   text,
  is_active   boolean NOT NULL DEFAULT true,
  start_date  timestamp with time zone,
  end_date    timestamp with time zone,
  created_at  timestamp with time zone NOT NULL DEFAULT now(),
  updated_at  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT cms_content_pkey PRIMARY KEY (id)
);


-- ============================================================
-- SECTION 11: FEEDBACK
-- ============================================================

-- [FIXED] user_feedback:
--   FIXED:   customer_id → user_profiles (was → auth.users — inconsistent)
--   ADDED:   order_id — feedback linked to a specific order (SRS FR C8)
--   ADDED:   product_id — feedback can be for a specific product (SRS FR A7)
CREATE TABLE public.user_feedback (
  id          uuid    NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid,                                                  -- [FIXED] → user_profiles
  order_id    uuid,                                                  -- [ADDED] linked order
  product_id  integer,                                               -- [ADDED] specific product (optional)
  rating      integer CHECK (rating >= 1 AND rating <= 5),
  comments    text,
  created_at  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_feedback_pkey PRIMARY KEY (id),
  CONSTRAINT user_feedback_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.user_profiles(id),
  CONSTRAINT user_feedback_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id),
  CONSTRAINT user_feedback_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id)
);


-- ============================================================
-- SECTION 12: ML RESULTS (CACHE)
-- ============================================================

-- [ADDED] ml_results — caches ML service output for 24 hours (Dev Guide Phase 2.5)
-- Main backend checks this table before calling the Python ML service.
-- If cached result is fresh (expires_at > now()), return cached. Otherwise call ML and re-cache.
CREATE TABLE public.ml_results (
  id            uuid    NOT NULL DEFAULT gen_random_uuid(),
  type          text    NOT NULL
                CHECK (type = ANY (ARRAY['forecast','restock','classify'])),
  product_id    integer,                                             -- NULL for classify/restock (applies to all)
  result_json   jsonb   NOT NULL,                                   -- full ML response stored as JSON
  generated_at  timestamp with time zone NOT NULL DEFAULT now(),
  expires_at    timestamp with time zone NOT NULL,                  -- generated_at + 24 hours
  CONSTRAINT ml_results_pkey PRIMARY KEY (id),
  CONSTRAINT ml_results_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id)
);


-- ============================================================
-- SECTION 13: SYNC LOGS (MOBILE OFFLINE SYNC)
-- ============================================================

-- [ADDED] sync_logs — tracks offline sync operations from the mobile app (NFR 8, Dev Guide)
-- When mobile reconnects, it pushes local operations here.
-- Backend processes each log entry and marks it as synced or conflicted.
CREATE TABLE public.sync_logs (
  id            bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  table_name    text    NOT NULL,                                    -- which table was affected
  record_id     text    NOT NULL,                                    -- ID of the affected record
  operation     text    NOT NULL
                CHECK (operation = ANY (ARRAY['insert','update','delete'])),
  payload       jsonb   NOT NULL,                                    -- full record data from mobile
  device_id     text,                                                -- which device sent this
  synced_at     timestamp with time zone,                           -- when server processed it
  is_synced     boolean NOT NULL DEFAULT false,
  conflict      boolean NOT NULL DEFAULT false,                      -- true = server overwrote local
  created_at    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT sync_logs_pkey PRIMARY KEY (id)
);


-- ============================================================
-- SECTION 14: AUDIT LOGS
-- ============================================================

-- [OK] audit_logs — already correct
CREATE TABLE public.audit_logs (
  id          uuid    NOT NULL DEFAULT gen_random_uuid(),
  user_id     uuid,
  action      character varying NOT NULL,
  entity_type character varying NOT NULL,
  entity_id   character varying,
  details     jsonb,
  ip_address  character varying,
  created_at  timestamp with time zone DEFAULT now(),
  CONSTRAINT audit_logs_pkey PRIMARY KEY (id),
  CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);


-- ============================================================
-- INDEXES (for query performance)
-- ============================================================

-- Orders — most queried by status and customer
CREATE INDEX idx_orders_payment_status  ON public.orders(payment_status);
CREATE INDEX idx_orders_customer_id     ON public.orders(customer_id);
CREATE INDEX idx_orders_created_at      ON public.orders(created_at);
CREATE INDEX idx_orders_created_by      ON public.orders(created_by);

-- Order items — queried heavily for reports and stamp counting
CREATE INDEX idx_order_items_order_id   ON public.order_items(order_id);
CREATE INDEX idx_order_items_product_id ON public.order_items(product_id);

-- Loyalty
CREATE INDEX idx_loyalty_stamps_user_id ON public.loyalty_stamps(user_id);
CREATE INDEX idx_loyalty_stamps_is_spent ON public.loyalty_stamps(is_spent);
CREATE INDEX idx_stamps_queue_is_synced  ON public.stamps_queue(is_synced);

-- Reservations
CREATE INDEX idx_reservations_status         ON public.reservations(status);
CREATE INDEX idx_reservations_reservation_time ON public.reservations(reservation_time);

-- Notifications
CREATE INDEX idx_notifications_user_id  ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read  ON public.notifications(is_read);

-- ML results
CREATE INDEX idx_ml_results_type        ON public.ml_results(type);
CREATE INDEX idx_ml_results_expires_at  ON public.ml_results(expires_at);

-- Sync logs
CREATE INDEX idx_sync_logs_is_synced    ON public.sync_logs(is_synced);


-- ============================================================
-- USEFUL VIEWS
-- ============================================================

-- Current stamp count per user (computed — do not use stored total_stamps)
-- Use this view instead of querying loyalty_stamps directly in the API.
CREATE OR REPLACE VIEW public.v_user_stamp_counts AS
SELECT
  u.id                                          AS user_id,
  u.email,
  u.account_id,
  u.qr_code,
  COUNT(s.id) FILTER (WHERE s.is_spent = false) AS active_stamps,
  u.excess_stamps                               AS excess_stamps,
  COUNT(s.id) FILTER (WHERE s.is_spent = true)  AS spent_stamps
FROM public.user_profiles u
LEFT JOIN public.loyalty_stamps s ON s.user_id = u.id
WHERE u.role = 'customer'
GROUP BY u.id, u.email, u.account_id, u.qr_code, u.excess_stamps;

-- Available seat count (computed — do not use stored available_tables)
CREATE OR REPLACE VIEW public.v_seat_availability AS
SELECT
  total_seats,
  (SELECT COUNT(*) FROM public.cafe_tables WHERE status = 'available')  AS available_seats,
  (SELECT COUNT(*) FROM public.cafe_tables WHERE status = 'occupied')   AS occupied_seats,
  (SELECT COUNT(*) FROM public.cafe_tables WHERE status = 'reserved')   AS reserved_seats
FROM public.restaurant_settings
WHERE id = 1;

-- Open pay-later orders (for staff to retrieve unpaid orders)
CREATE OR REPLACE VIEW public.v_open_orders AS
SELECT
  o.id,
  o.receipt_number,
  o.order_type,
  o.total_amount,
  o.created_at,
  o.created_by,
  u.first_name  AS customer_first_name,
  u.last_name   AS customer_last_name
FROM public.orders o
LEFT JOIN public.user_profiles u ON u.id = o.customer_id
WHERE o.payment_timing = 'pay_later'
  AND o.payment_status = 'unpaid'
  AND o.status = 'open';


-- ============================================================
-- ISSUE SUMMARY (all 20 issues reviewed)
-- ============================================================
/*
  CRITICAL FIXES:
  [1]  FIXED  — Dual customer system merged: old public.customers removed,
                orders.customer_id now → user_profiles, qr_code moved to user_profiles
  [2]  FIXED  — total_stamps removed from customers; use v_user_stamp_counts view instead
  [3]  REMOVED — time_slots table dropped; operating hours handled by restaurant_settings only
  [4]  ADDED  — ml_results table for 24-hour ML cache (Dev Guide Phase 2.5)
  [5]  ADDED  — notifications table (SRS FR A8, Dev Guide 2.9)
  [6]  ADDED  — sync_logs table (NFR 8, Dev Guide mobile handover)
  [7]  ADDED  — stamps_queue table (offline QR scan queuing, NFR 8)
  [8]  FIXED  — orders: added order_type, payment_timing, payment_status, receipt_number,
                refunded_at, refund_reason, stamps_credited; fixed status values for POS
  [9]  REMOVED — orders.table_id removed (SRS FR S3: no table assignment required)
  [10] FIXED  — loyalty_rewards.reward_item text → product_id integer FK
  [11] FIXED  — loyalty_rewards.redeemed_by_staff_id → user_profiles (was → auth.users)
  [12] FIXED  — user_feedback: customer_id → user_profiles; added order_id and product_id FKs
  [13] FIXED  — reservations: removed 'completed' status; added approved_by and cancelled_at
  [14] NOTE   — product_recipe kept (good undocumented feature, recipe-based deduction)
  [15] FIXED  — cafe_tables: removed 'cleaning' status (not in SRS)
  [16] FIXED  — categories: removed circular linked_product_id FK back to products
  [17] FIXED  — restaurant_settings: removed available_tables (now computed via view)
  [18] OK     — audit_logs unchanged (already correct)
  [19] NOTE   — raw_materials_inventory.cost_per_unit kept (harmless, useful for future)
  [20] FIXED  — order_items: added is_stamp_eligible boolean snapshot
*/