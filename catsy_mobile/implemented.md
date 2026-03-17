# Catsy POS — Implementation Review & Status

> **Project**: `catsy_pos` · Flutter (Dart SDK ^3.10.4) · Local-first, offline-capable staff POS for Catsy Café  
> **Backend**: `api-bridge` · FastAPI + Supabase (PostgreSQL + RLS)  
> **Last Audited**: 2026-02-25

---

## 🏗️ Architecture Overview

The application follows a local-first architecture using **Riverpod** for state management and **Drift (SQLite)** for offline functionality. 
- Local reads/writes happen first.
- The `SyncEngine` handles pushing updates to the `api-bridge` and pulling down incremental changes.
- **Status:** The architectural foundation is solidly implemented.

---

## 📱 UI & Feature State (What is Actually Implemented)

After auditing the codebase, here is the *true* state of the UI and features:

### ✅ Finished & Functional UI
- **Auth (`/auth`)**: Login & Splash Screens are complete. Token storage via secure storage works as intended.
- **Dashboard (`/dashboard`)**: The main dashboard UI is built. Staff can see statistics, open/close restaurant toggle, and table lists. 
- **Product Catalog & Cart (`/order`)**: `product_catalog_screen.dart` and `order_builder_screen.dart` are built for item selection.
- **Checkout (`/order`)**: `payment_screen.dart` and `receipt_screen.dart` are UI-complete for processing the transaction.
- **Loyalty & Rewards (`/loyalty` & `/reward`)**: 
  - `qr_scanner_screen.dart` successfully scans customers.
  - `customer_search_screen.dart` allows manual lookup.
  - `claim_reward_screen.dart` UI is built (but requires fixing hardcoded data).
- **Reservations (`/reservation`)**: List screen and creation dialog UI are fully built.
- **Tables (`/table_management`)**: Table grid layout and statuses are visible.
- **Inventory (`/inventory`)**: Stock overview screen exists.
- **History (`/history`)**: Order history and transaction lists are built.

### � Unfinished / Placeholder UI
- **Order Summary (`order_summary_screen.dart`)**: **[NOT IMPLEMENTED]** Currently just a blank scaffold that says `"Order Summary — TODO"`. Staff cannot review orders logically before hitting pay.
- **Dashboard Empty Actions**: Buttons inside the Action Required card (like "Pay", "Bill") have empty `onTap: () {}` callbacks.
- **Dashboard Data Wiring**: The dashboard relies on some mock aggregations. Order/Revenue charts and real-time synchronization metrics are not fully wired together.

---

## 🔌 API & Integration Gaps (Backend Mismatches)

Even though UI exists, the following integrations are broken or incomplete between `catsy_pos` and `api-bridge`:

1. **Staff Reservation Creation (404 Error)**
   - **Issue:** The POS attempts to create reservations by calling `POST /api/staff/reservations`. 
   - **Reality:** The API Bridge `staff_reservation_router` only handles `GET` and `PATCH`. Staff creation requests fail.
2. **Hardcoded Staff ID in Rewards**
   - **Issue:** `ClaimRewardScreen.dart` uses `static const String _staffId = 'staff-001';` to claim rewards.
   - **Reality:** Needs to dynamically fetch the Staff ID from the Auth/Session state.
3. **Reward Status Source**
   - **Issue:** POS relies on `GET /loyalty/status` to fetch all rewards. 
   - **Reality:** This endpoint is designed for the customer web app. The POS does not have a dedicated staff-facing endpoint to list universal rewards or properly format them.

---

## 🚀 What to Touch Next (Actionable Roadmap)

If you are picking up development, target these areas in order of priority:

### Priority 1: Complete the Order Flow & POS Essentials
1. **Build `order_summary_screen.dart`**: Render a list of `CartItem` elements from the `CartProvider` so staff can confirm items, add-ons, and totals before proceeding to payment.
2. **Fix Hardcoded Identity**: Update `claim_reward_screen.dart` to pull the staff ID from the `authNotifierProvider` instead of using `'staff-001'`.

### Priority 2: Fix Backend Integration Gaps
3. **Staff Reservation API**: In `api-bridge`, add the `create_reservation` method to the staff router, mirroring what the customer router does, so staff can book walk-in reservations.
4. **Order-to-Stamp Automation**: In the POS `payment_screen.dart`, when a checkout succeeds, automatically trigger the customer stamp API rather than requiring manual stamping for standard orders.

### Priority 3: Polish & Real-time Connectivity
5. **Dashboard Quick Links**: Wire up the "Pay" and "Bill" chips in `dashboard_screen.dart` to actually navigate or open modal handlers.
6. **SSE Stream (Events)**: Hook up the POS to listen to the API Bridge `/api/events` SSE stream. This allows tables and incoming orders to update in real-time on the dashboard, bypassing the need for manual refresh gestures.
