**CUTshier**

POS & Inventory Management System

_for Cutsy Coffee_

**DEVELOPER TEAM - DEVELOPMENT PHASES GUIDE Web (Customer Portal + Admin Panel) & Backend API + ML Service - Focus Track**

Version 1.2 (Updated) | BS Computer Science - CS17/L Software Engineering | UM Tagum College

# Overview: Development Strategy

CUTshier is built in three layers: Web (Customer Portal + Admin Panel), Backend API, and a Machine Learning service. This guide covers all phases from setup to deployment and mobile handover.

- Backend API - the core foundation all platforms depend on
- Admin Panel - must be configured first before any other user can do anything
- Customer Portal - web-only, ships independently of mobile
- ML Service - Python microservice, called by backend, results shown in Admin Reports
- Mobile App - built last, handed off after web + backend + ML are live

Team Structure (Recommended Split)

Backend Developer - API, database, authentication, business logic, sync engine, ML service integration

Frontend Developer (Web) - Customer portal, Admin panel, UI/UX, component states

Shared responsibility - Integration testing, API contracts, error handling, documentation

## Overall Phase Timeline

| **Phase**                       | **Focus Area**                                                           | **Status**   |
| ------------------------------- | ------------------------------------------------------------------------ | ------------ |
| Phase 1 - Setup & Foundation    | Project scaffolding, DB schema, auth, dev environment                    | [x] Done     |
| Phase 2 - Core Backend API      | All REST endpoints, business logic, offline sync prep                    | [x] Done     |
| Phase 2.5 - ML Service          | Python Flask ML microservice: forecasting, classification, restock       | [ ] New      |
| Phase 3 - Admin Web Panel       | Full admin UI: products, inventory, employees, CMS, reports + ML results | [x] Done     |
| Phase 4 - Customer Web Portal   | Customer UI: menu, reservations, loyalty stamps, QR code                 | [x] Done     |
| Phase 5 - UI/UX Polish          | All button states, error messages, loading states, edge cases            | [x] Done     |
| Phase 6 - Integration & Testing | End-to-end testing, API validation, cross-browser, security, ML tests    | [/] Active   |
| Phase 7 - Deployment & Handover | Production setup, documentation, mobile prep handover                    | [ ] Next     |

**[x] PHASE 1: SETUP & FOUNDATION Project scaffolding · Database schema · Authentication · Dev environment**

## Goals for Phase 1

Before writing a single feature, the entire team must agree on architecture, set up their local environments, and establish the database - because changing the schema mid-project causes major rework.

### 1.1 Backend Developer - Start Here

- Initialize the backend project (Node.js/Express or Laravel - team decides)
- Set up PostgreSQL (or MySQL) database on local and dev server
- Design and finalize the full database schema:
  - Tables: users, employees, products, categories, inventory, orders, order_items, transactions, stamps, reservations, seats, time_slots, rewards, reward_codes, feedback, notifications, sync_logs, ml_results
  - transactions table must include: payment_method (Cash | GCash | Maya), amount_tendered, change_due columns - required for FR S5
  - ml_results table: id, type (forecast | restock | classify), product_id, result_json, generated_at, expires_at
  - Define all foreign keys, indexes, and soft delete columns
- Set up migration scripts (e.g., Sequelize, Knex, or Eloquent)
- Configure .env files for dev/staging/production
- Set up JWT authentication module (separate tokens for admin web vs. customer web vs. mobile)
- Set up role-based access middleware (admin, staff, customer, guest)
- Initialize Git repository with proper branching strategy (main, dev, feature/\*)

**\[ADDED\] SQLite schema stub for mobile handover (NFR 8)**

Prepare a SQLite schema document alongside the main DB schema. The mobile developer will need:

\- Tables to mirror offline: orders, order_items, inventory (read-only), stamps_queue, sync_logs

\- sync_logs columns: id, table_name, record_id, operation, payload, synced_at, conflict (boolean)

\- Conflict rule: server always wins - local record is discarded and overwritten on sync

This does not need to be built yet - just documented for Phase 7 handover.

### 1.2 Frontend Developer - Start Here

- Initialize frontend project (React + Vite or Next.js - team decides)
- Set up two separate apps or route groups: /admin and /portal (customer)
- Install and configure Tailwind CSS or chosen design system
- Create reusable component library stubs: Button, Input, Modal, Toast, Badge, Table, Card, SkeletonLoader
- Set up Axios or Fetch wrapper for all API calls with global error interceptor
- Set up React Router with protected routes (role-based guards)
- Create placeholder pages for all major screens - no logic yet, just route shells

### 1.3 Shared / Both Developers

- Agree on API contract format: RESTful JSON, consistent response envelope
- Define standard API response format (see box below)
- Set up Postman collection for all planned endpoints
- Agree on error code conventions (SCREAMING_SNAKE_CASE)

Standard API Response Envelope - Agree on This First

Success: { success: true, data: { ... }, message: 'OK' }

Error: { success: false, error: { code: 'INVALID_CREDENTIALS', message: 'Email or password is incorrect.' } }

List: { success: true, data: \[ ... \], meta: { total: 50, page: 1, limit: 20 } }

All API responses must follow this format. Never return raw data without the envelope.

Error codes must be SCREAMING_SNAKE_CASE strings - the frontend maps these to user-friendly messages.

**Deliverables to finish before next phase**

✓ Git repo initialized, all developers can clone and run locally

✓ Database migrations run successfully on local (including payment_method, amount_tendered, change_due columns, ml_results table)

✓ JWT auth returns a valid token on POST /api/auth/login

✓ All route shells exist in the frontend (even if blank pages)

✓ Postman collection created with all planned endpoint names

✓ .env.example committed to repo with all required keys documented

✓ SQLite schema stub document created and saved to /docs/mobile-sqlite-schema.md

**[x] PHASE 2: CORE BACKEND API All REST endpoints · Business logic · Validation · Sync engine setup**

## Goals for Phase 2

The backend developer builds ALL endpoints before the frontend starts connecting them. The frontend developer can use Postman or mock data during this phase. Never build frontend and backend in parallel without an agreed API contract - it causes integration hell.

### 2.1 Authentication & User Management

- POST /api/auth/register - customer account creation
- POST /api/auth/login - returns JWT (scope: customer | admin | staff)
- POST /api/auth/logout - token invalidation
- GET /api/auth/me - returns current user profile
- PUT /api/auth/password - change password
- Cross-platform enforcement: admin token only valid on admin routes, staff token only valid on POS routes

### 2.2 Product & Category API

- GET /api/products - public list with availability and stamp eligibility flags
- POST /api/admin/products - create product (admin only)
- PUT /api/admin/products/:id - update product
- DELETE /api/admin/products/:id - soft delete
- PUT /api/admin/products/:id/stamp-eligible - toggle stamp eligibility
- GET/POST/PUT/DELETE /api/admin/categories

### 2.3 Inventory API

- GET /api/admin/inventory - list all inventory with current levels and min thresholds
- PUT /api/admin/inventory/:id - update stock levels
- POST /api/admin/inventory/adjust - record adjustments (damaged, recount, etc.)
- GET /api/admin/inventory/low-stock - products below minimum threshold
- Auto-deduct on order placement - build as internal service, not a public endpoint
- Auto-restore on void or refund - internal service call, triggered by void/refund endpoints

### 2.4 Order & Transaction API

- POST /api/staff/orders - create order (dine-in/take-out, pay-now/pay-later)
- PUT /api/staff/orders/:id - modify order (add items, change type)
- GET /api/staff/orders?status=open - retrieve all open pay-later orders awaiting payment
- POST /api/staff/orders/:id/pay - process payment; body must include: payment_method (Cash|GCash|Maya), amount_tendered; response must include: change_due (for cash payments)
- POST /api/staff/orders/:id/void - void order and restore inventory
- POST /api/staff/orders/:id/refund - process refund, restore inventory, deduct stamps if earned
- GET /api/admin/orders - full order history with filters (date, status, staff, payment_method)
- GET /api/customer/orders - customer purchase history (linked account only)

**\[ADDED\] Pay-later open orders endpoint (FR S3, FR S5)**

GET /api/staff/orders?status=open is critical for the pay-later flow.

Staff must be able to retrieve a customer's open unpaid order when they are ready to pay.

Response should include: order_id, items, total, order_type, created_at.

The mobile POS app will also need this endpoint - document in Phase 7 handover.

**\[ADDED\] Payment method and cash change (FR S5)**

POST /api/staff/orders/:id/pay request body:

{ payment_method: "Cash" | "GCash" | "Maya", amount_tendered: 500 }

Response body must include:

{ receipt_id, total, payment_method, amount_tendered, change_due: 50 }

change_due is computed server-side: change_due = amount_tendered - total (only for Cash).

For GCash/Maya: amount_tendered = total, change_due = 0.

### 2.5 Loyalty Stamp API

- GET /api/customer/stamps - get current stamp count, visual grid state (0-9 filled), and excess queued count
- GET /api/staff/members?search= - search customer accounts by name or email for member list lookup on handheld device; returns max 10 results; staff JWT only
- POST /api/staff/stamps/credit - credit stamps to account (after QR scan or member list selection); body: { customer_id, order_id }
- POST /api/customer/rewards/generate - generate reward QR code + unique text code (single-use); requires all 9 stamps filled
- POST /api/staff/rewards/redeem - validate and redeem reward code, deduct 9 stamps, carry excess to next cycle
- Stamp overflow logic: if total stamps > 9, store excess separately in stamps table, apply after next claim

**\[ADDED\] Member list search endpoint (FR S8)**

GET /api/staff/members?search={query} is required for the two-method account lookup.

Staff can either scan QR code OR search by customer name/email from a list.

Response: \[{ id, name, email, stamp_count, qr_id }\] - limited to 10 results.

This endpoint requires staff JWT. Guest/customer tokens must be rejected (403).

### 2.6 Reservation API

- GET /api/reservations/slots - public endpoint: opening time, closing time, current seat vacancy
- POST /api/reservations - create reservation (logged-in or guest with name/contact)
- GET /api/staff/reservations - list all pending/approved reservations, sorted by time, with overlap flag
- PUT /api/staff/reservations/:id - approve or decline
- DELETE /api/reservations/:id - customer cancels their own reservation
- POST /api/staff/seats/:id/free - mark no-show seat as free
- Auto-notify: trigger notification on approval/decline/cancellation/no-show warning

### 2.7 Seat Map API

- GET /api/seats - current state of all seats (Available, Occupied, Reserved)
- PUT /api/staff/seats/:id - toggle Available/Occupied
- GET /api/seats/count - computed vacancy count for customer portal
- Auto-shift: reserved seat auto-becomes Occupied when time slot begins (cron job or scheduled check)

### 2.8 Admin Panel APIs

- GET/PUT /api/admin/employees - manage staff accounts
- GET /api/admin/reports/sales - daily/monthly sales reports (filterable by date, payment_method)
- GET /api/admin/reports/products - calls ML service for classification; falls back to simple rank if ML unavailable
- GET /api/admin/reports/inventory - calls ML service for restock prediction; falls back to simple depletion if ML unavailable
- GET /api/admin/reports/forecast/:product_id - calls ML service for 7-day sales forecast
- GET/POST/PUT/DELETE /api/admin/cms - banners, announcements, promos
- GET/PUT /api/admin/operating-hours - opening time + closing time only (replaces fixed time slots)
- GET /api/admin/rewards - list claimable reward items (linked to existing products)
- POST/PUT/DELETE /api/admin/rewards - manage reward items (must reference existing product_id)
- GET /api/admin/apk/download - returns APK file download (admin JWT only; 403 for all other roles)

**\[ADDED\] APK download endpoint (FR A11)**

GET /api/admin/apk/download must be protected: admin JWT required, 403 for staff/customer.

Returns the POS APK file as a binary download (Content-Disposition: attachment).

This endpoint must also be verified in Phase 6 security checklist.

### 2.9 Notification API

- GET /api/notifications - fetch unread notifications for current user role
- PUT /api/notifications/:id/read - mark as read
- Internal triggers: low-stock, reservation approval/decline/cancel, refund, sync complete, no-show warning, ML restock alert

### 2.10 Feedback API

- POST /api/customer/feedback - submit star rating + review for an order
- GET /api/admin/feedback - view all feedback (filterable by product, date, rating)

**Deliverables to finish before next phase**

✓ All endpoints return correct data shapes as agreed in the API contract

✓ All endpoints validated (wrong input returns proper error with code + message)

✓ JWT middleware works on all protected routes

✓ Stamp overflow logic tested via Postman - test all cases:

\- 0 stamps + 9 eligible products → all 9 slots fill, 0 excess

\- 8 stamps + 4 eligible products → all 9 slots fill, 3 excess queued

\- Claim with 3 excess → card resets, fills with 3 stamps

✓ GET /api/staff/orders?status=open returns correct open pay-later orders

✓ POST /api/staff/orders/:id/pay returns change_due for cash payments

✓ GET /api/staff/members?search= returns matching accounts (403 for non-staff)

✓ GET /api/admin/apk/download returns 403 for staff and customer tokens

✓ GET /api/admin/operating-hours returns opening and closing time

✓ Inventory auto-deduct works when an order is placed

✓ Inventory auto-restore works on void and on refund

✓ Postman collection is fully up to date and shareable with frontend dev

✓ Seed data exists: at least 10 products, 3 categories, 1 admin, 1 staff, 1 customer, operating hours set

**[ ] PHASE 2.5: ML SERVICE SETUP Python Flask microservice · Sales forecasting · Product classification · Restock prediction**

## Goals for Phase 2.5

Build a separate Python Flask microservice that handles all machine learning logic. The main backend calls this service when the admin views the Reports page. Results are cached for 24 hours so the model does not re-run on every page load.

This directly implements FR A5 (Product Sales Analysis) and FR A6 (Inventory Analysis) from the SRS.

**Why a Separate Python Service?**

Machine learning libraries (Prophet, scikit-learn, pandas) are Python-native - no good equivalents in Node/Laravel.

Keeping ML isolated means a bug in the ML service never crashes the main API.

The ML model can be retrained or updated without touching the backend or frontend.

Results are served as simple JSON - the backend treats ML data like any other data source.

### 2.5.1 Architecture

How the ML service connects to everything:

| **Layer**                   | **Role**                                                                                                                              |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| PostgreSQL Database         | ML service reads order history and inventory data directly from the same database as the main backend                                |
| Python Flask ML Service     | Runs Prophet forecasting, K-Means classification, and moving average restock prediction. Exposes 4 internal endpoints.               |
| Main Backend (Node/Laravel) | Calls the ML service when admin opens Reports. Caches results in ml_results table for 24 hours. Returns combined data to frontend.   |
| Admin Web Panel             | Displays ML results in the Reports page - forecast chart, best/slow mover labels, restock warnings. No direct connection to ML.      |
| Mobile App                  | Does NOT connect to ML service - ML is admin-only.                                                                                   |

### 2.5.2 Setup & Installation

- Create a separate folder in the project: /ml-service
- Install Python dependencies:
  - pip install flask prophet scikit-learn pandas numpy psycopg2-binary
- Folder structure:
  - /ml-service/app.py - Flask entry point, all routes
  - /ml-service/db.py - database connection helper
  - /ml-service/forecast.py - Prophet sales forecasting
  - /ml-service/classify.py - K-Means product classification
  - /ml-service/restock.py - moving average restock prediction
  - /ml-service/requirements.txt - all pip dependencies
- ML service runs on port 5001 (main backend on port 3000 or 8000)
- Both services connect to the same PostgreSQL database using the same .env credentials

### 2.5.3 Feature 1 - Sales Forecasting (FR A5)

Predicts how many units of a product will sell in the next 7 days based on historical order data.

- Algorithm: Facebook Prophet - handles weekly patterns (busier weekends) automatically
- Input: daily sales totals per product from order_items joined with orders table
- Output: predicted units sold for the next 7 days with confidence range
- Minimum data required: 14 days of sales history - show 'Not enough data yet' if less

**What Admin Sees - Forecast**

Product: Caramel Latte

Last 7 days avg: 18 cups/day

Next 7 days forecast: \[chart showing predicted daily sales\]

Predicted total next week: ~126 cups

If stock is low: Warning badge - 'Current stock may not meet forecasted demand'

### 2.5.4 Feature 2 - Product Classification (FR A5)

Automatically labels each product as Best Seller, Average, or Slow Mover based on the last 30 days of sales.

- Algorithm: K-Means clustering with 3 clusters (n_clusters=3)
- Input: total units sold per product in the last 30 days
- Output: each product labeled as Best Seller / Average / Slow Mover
- Minimum data required: at least 30 days and 5 orders - otherwise use simple rank sorting

**What Admin Sees - Product Classification**

Best Sellers: Iced Americano (200 sold), Caramel Latte (180 sold), Chocolate Cake (120 sold)

Average Movers: Matcha Latte (75 sold), Cheese Bread (60 sold)

Slow Movers: Hot Chamomile (12 sold), Lemon Tart (8 sold)

Labels shown as colored badges on the Product Analysis table in admin reports.

### 2.5.5 Feature 3 - Restock Prediction (FR A6)

Predicts how many days until each inventory item runs out based on current stock and average daily consumption rate.

- Algorithm: Moving Average - average daily consumption over last 7 days
- Formula: days_remaining = current_stock / avg_daily_consumption
- If days_remaining < 3 → trigger low-stock notification to admin
- If days_remaining < 7 → show orange warning badge in inventory table
- Input: inventory table (current stock) + order_items (daily consumption history)
- Output: estimated days remaining per product + restock urgency label

**What Admin Sees - Restock Prediction**

| Ingredient    | Current Stock | Avg Daily Use  | Est. Days Left | Status              |
| ------------- | ------------- | -------------- | -------------- | ------------------- |
| Caramel Syrup | 2 bottles     | 0.6 bottles    | 3 days         | RESTOCK NOW (red)   |
| Coffee Beans  | 5 kg          | 0.35 kg        | 14 days        | OK (green)          |
| Milk          | 8 liters      | 1.1 liters     | 7 days         | Restock Soon (orange) |

Notification sent to admin when any item drops below 3 days remaining.

### 2.5.6 ML API Endpoints (Internal Only)

These endpoints are called by the main backend only - never directly by the frontend or mobile app.

| **Endpoint**                 | **Description**                                                                                                   |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| GET /ml/forecast/:product_id | Returns 7-day forecast for one product. If < 14 days data: returns { status: 'insufficient_data' }               |
| GET /ml/classify             | Returns all products with Best Seller / Average / Slow Mover labels. If < 30 days: returns simple rank order.    |
| GET /ml/restock              | Returns all inventory items with days_remaining, avg_daily_use, and urgency label.                               |
| GET /ml/health               | Health check - returns { status: 'ok' }. Main backend calls this on startup to verify ML service is running.     |

### 2.5.7 Caching - 24-Hour Results

- When admin opens Reports, backend checks ml_results table first
- If cached result exists and expires_at > now → return cached result immediately (no ML run)
- If no cache or expired → call ML service, store result in ml_results table with expires_at = now + 24 hours
- This means ML runs at most once per day - not on every admin click
- Force refresh button in admin Reports page - clears cache and reruns ML immediately

### 2.5.8 Cold Start - Not Enough Data

| **Data Available** | **What Admin Sees**                                                                      |
| ------------------ | ---------------------------------------------------------------------------------------- |
| 0 orders           | 'No sales data yet. ML predictions will appear after the first sales are recorded.'      |
| 1-13 days of data  | Restock prediction works. Forecast shows: 'Need 14 days of data for forecasting.'        |
| 14-29 days of data | Forecast + restock work. Classification shows: 'Need 30 days for product classification.'|
| 30+ days of data   | All three ML features fully active.                                                      |

### 2.5.9 Fallback - If ML Service is Down

- Main backend always checks /ml/health before calling ML endpoints
- If ML service is unreachable → backend falls back to simple database queries:
  - Classification fallback: rank products by total sold in last 30 days - no K-Means
  - Restock fallback: show current stock vs minimum threshold - no consumption prediction
  - Forecast fallback: show last 7 days average - no Prophet prediction
- Admin sees a yellow info banner: 'ML predictions temporarily unavailable. Showing basic data.'
- This ensures the Reports page never breaks even if the ML service crashes

**Deliverables to finish before next phase**

✓ /ml-service folder created with all Python files and requirements.txt

✓ GET /ml/health returns { status: 'ok' }

✓ GET /ml/classify returns product labels (test with seed data)

✓ GET /ml/restock returns days_remaining for all inventory items

✓ GET /ml/forecast/:product_id returns 7-day forecast (use seed data with 14+ days)

✓ insufficient_data response works when < 14 days of sales

✓ Main backend caches ML results in ml_results table for 24 hours

✓ Fallback works when ML service is stopped - reports page still loads

✓ Low-stock notification triggers when days_remaining < 3

✓ Force refresh button in admin panel clears cache and re-calls ML service

**[x] PHASE 3: ADMIN WEB PANEL Full admin UI: products · inventory · employees · CMS · reports with ML · APK download**

## Goals for Phase 3

Build the complete Admin Web Panel. The admin is the first real user of the system - they configure products, inventory, and operating hours before customers or staff can do anything. Connect to the live backend from Phase 2 and ML service from Phase 2.5.

### 3.1 Admin Login Page

| **Screen Element** | **Details**                                                                                      |
| ------------------ | ------------------------------------------------------------------------------------------------ |
| Route              | /admin/login                                                                                     |
| Fields             | Email, Password                                                                                  |
| Login Button       | Disabled while fields are empty; shows spinner on submit                                         |
| Error Handling     | Wrong credentials → red toast: 'Incorrect email or password.'                                    |
| Redirect           | On success → /admin/dashboard                                                                    |
| Guard              | If already logged in, redirect to dashboard; staff login returns 'You do not have admin access.' |

### 3.2 Dashboard

- Summary cards: Today's Sales, Orders Today, Low Stock Alerts count, Pending Reservations
- Quick links: Go to Reports, View Inventory, Manage Reservations
- Notification bell icon in header - badge count of unread notifications

### 3.3 Product Management

- Table listing all products with: Name, Category, Price, Availability toggle, Stamp Eligible toggle, Reward Item toggle
- Add Product button → opens modal/drawer with form
- Edit / Delete actions per row
- Reward Item toggle - inline per product row; replaces separate reward items section

**\[ADDED\] Reward items must be product pickers, not free-text (FR A3)**

The "Add Reward Item" form must use a product picker (searchable dropdown of existing products).

Reward items link to existing product records - they are NOT free-text entries.

This ensures inventory deduction works correctly when a reward is claimed in-store.

Display: product name, image thumbnail, and category in the reward items list.

| **State**        | **Button / Label**   | **What Shows / Behavior**                                                                                     |
| ---------------- | -------------------- | ------------------------------------------------------------------------------------------------------------- |
| Idle / Ready     | Save Product         | All fields blank or pre-filled. Button enabled only when required fields (name, price, category) have values. |
| Saving...        | Saving... (disabled) | Spinner inside button. Inputs locked. User cannot submit twice.                                               |
| Success          | Save Product         | Green toast: 'Product saved successfully.' Modal closes. Table refreshes.                                     |
| Validation Error | Save Product         | Red inline message below each invalid field. Button stays enabled so user can fix and retry.                  |
| Server Error     | Save Product         | Red toast: 'Something went wrong. Please try again.' Modal stays open.                                        |
| Delete Confirm   | Delete (red)         | Confirmation dialog: 'Are you sure you want to delete \[Product Name\]?' Confirm red, Cancel gray.            |

### 3.4 Inventory Management

- Table: Product name, Current Stock, Min Threshold, Est. Days Remaining (from ML), Last Updated, Adjust button
- Rows highlighted red when stock is at or below minimum threshold
- Rows highlighted orange when ML predicts < 7 days remaining
- Adjustment modal: reason dropdown (Restock, Damaged, Incorrect Count), quantity field, notes

| **State**             | **Button / Label**   | **What Shows / Behavior**                                                                        |
| --------------------- | -------------------- | ------------------------------------------------------------------------------------------------ |
| Idle                  | Adjust Stock         | Button active. Reason and quantity required.                                                     |
| Saving                | Saving... (disabled) | Spinner. Inputs locked.                                                                          |
| Success               | Adjust Stock         | Green toast: 'Inventory updated.' Table row refreshes with new value.                            |
| Low Stock (threshold) | - (auto)             | Row highlighted red. Orange badge 'LOW'. Notification sent to admin.                             |
| Restock Soon (ML)     | - (auto)             | Row highlighted orange. Badge 'RESTOCK SOON - ~N days left'. Based on ML prediction.            |
| Zero Stock            | - (auto)             | Row highlighted dark red. Badge 'OUT OF STOCK'. Product auto-marked unavailable on portal.       |
| ML Unavailable        | - (auto)             | Yellow info banner: 'Restock predictions temporarily unavailable. Showing basic data.'           |

### 3.5 Employee Management

- List of staff accounts with name, email, status (Active/Inactive)
- Create Employee - generates credentials for mobile POS login
- Deactivate / Reactivate toggle per employee

| **State**       | **Button / Label**  | **What Shows / Behavior**                                                                                                    |
| --------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Create Employee | Create Account      | Form: Name, Email. On success: green toast 'Account created.' If email exists: 'An account with this email already exists.' |
| Deactivate      | Deactivate (orange) | Confirm dialog: 'This will prevent the employee from logging in.' On confirm: status → Inactive, row grays out.              |
| Reactivate      | Reactivate (green)  | No confirmation needed. Status changes to Active immediately.                                                                |

### 3.6 Reservation Management (Admin - Read Only)

- List view: date, time, customer name, guest count, status - sorted by time
- Grouped by date, ordered earliest to latest
- Overlap flag: if two reservations are within the same hour, show orange badge 'Multiple reservations at this time'
- Admin view only - no approve/decline (staff do that on mobile app)
- Filter by date range and status

### 3.7 Seat Overview (Admin - Read Only)

- Total seat count display: Available / Occupied / Reserved as numbers
- Visual grid showing seat states: Green = Available, Red = Occupied, Blue = Reserved
- Reserved seats show tooltip: customer name (or 'Guest'), time, guest count
- Note displayed: 'Seat state is managed by staff on the mobile app.'

### 3.8 Operating Hours Configuration

- Two fields only: Opening Time and Closing Time
- Default on first run: 5:00 PM to 12:00 AM - pre-populated with banner
- Changes reflect immediately on customer reservation page
- Warning if a pending reservation exists outside new hours when admin edits

### 3.9 Reports & Analytics (with ML)

- Sales Report: date range picker, chart (bar/line), table with daily totals and payment method breakdown (Cash / GCash / Maya)
- Product Analysis - ML powered:
  - Best Seller / Average / Slow Mover badges per product (from ML classification)
  - 7-day sales forecast chart per product (from ML Prophet)
  - If insufficient data: 'Not enough data yet. Check back after 30 days of sales.'
- Inventory Analysis - ML powered:
  - Estimated days remaining per item (from ML moving average)
  - Restock urgency labels: OK / Restock Soon / Restock Now
  - If ML unavailable: fallback to current stock vs minimum threshold display
- Feedback Viewer: star rating list, customer name, comment, date - flat list, no analysis tools
- Force Refresh button - clears ML cache and reruns predictions immediately

### 3.10 CMS - Content Management

- Single hero image upload for the landing page banner
- Announcements section - text only, toggle active/inactive
- Promos - title, description, start/end date
- All changes reflect immediately on customer portal

### 3.11 APK Download

**\[ADDED\] APK download screen (FR A11) - was missing, now added**

Section in admin sidebar: Settings > POS App Download

Displays: current APK version, file size, last updated date

Button: "Download POS App (APK)" - calls GET /api/admin/apk/download

Instructions shown: "Install this APK on the staff Android handheld device."

Only visible to admin - staff accounts do not see this section.

**Deliverables to finish before next phase**

✓ Admin can log in and access all sections

✓ Product CRUD works end-to-end including stamp eligible and reward item toggles

✓ Inventory table shows ML-predicted days remaining

✓ Reports page shows ML classification badges and forecast chart

✓ 'Not enough data' message shows correctly for new installs

✓ ML unavailable fallback banner shows when ML service is stopped

✓ Operating hours config: two-field form, pre-populated defaults on first run

✓ Reservation list sorted by time with overlap flag

✓ Force Refresh button clears cache and reruns ML

✓ APK download section visible and functional for admin only

✓ CMS content published by admin appears on the customer portal

✓ All button states and error messages implemented

✓ **SOLID Backend Refactor:** Isolated DB logic into repositories for all Phase 3 domains.

**[x] PHASE 4: CUSTOMER WEB PORTAL Menu · Seat vacancy · Reservations · Loyalty stamps · QR code · Purchase history**

## Goals for Phase 4

Build the customer-facing web portal. Most features are public (no login needed), but loyalty features require authentication. Customers must never see admin or staff data.

### 4.1 Home / Landing Page

- Café branding: name, tagline, hero image/banner (from CMS)
- Menu preview with product categories
- Seat vacancy counter: live count - '5 seats available' - updates in real-time via polling
- Reserve a Seat CTA button
- Announcements and promos from CMS
- Café location: embed Google Maps iframe showing café location (static embed - no live tracking required)

### 4.2 Menu Page

- Grid of products grouped by category
- Each product card: image, name, price, availability badge
- Unavailable products shown grayed out with 'Currently Unavailable' badge
- No ordering from web - menu is display only

### 4.3 Authentication Pages

- Register page - fields: name, email, password, confirm password
- Login page - email + password
- Guest option available on reservation flow - no registration needed

| **State**            | **Button / Label**       | **What Shows / Behavior**                                                                  |
| -------------------- | ------------------------ | ------------------------------------------------------------------------------------------ |
| Idle                 | Log In / Register        | Button disabled until required fields are filled.                                          |
| Submitting           | Logging in... (disabled) | Spinner in button. Fields locked.                                                          |
| Invalid Credentials  | Log In                   | Red inline error: 'Incorrect email or password. Please try again.'                         |
| Email Already Exists | Register                 | Red inline error below email: 'An account with this email already exists. Log in instead?' |
| Weak Password        | Register                 | Red inline error: 'Password must be at least 8 characters.'                                |
| Success - Login      | Log In                   | Redirect to /portal/dashboard. Green toast: 'Welcome back, \[Name\]!'                      |
| Success - Register   | Register                 | Redirect to /portal/dashboard. Green toast: 'Account created! You are now logged in.'      |

### 4.4 Reservation Flow

- Step 1: Select Date (today or tomorrow only - max 1 day in advance)
- Step 2: Select Time - time picker within operating hours (e.g., 5:00 PM to 12:00 AM)
- Step 3: Enter Guest Count (1-10) and Name/Contact (for guest users)
- Step 4: Review and Confirm
- Step 5: Confirmation screen - reservation pending staff approval

| **State**          | **Button / Label**               | **What Shows / Behavior**                                                                    |
| ------------------ | -------------------------------- | -------------------------------------------------------------------------------------------- |
| No Seats Available | - (Reserve hidden)               | Message: 'No seats available for this date. Please check back later.' Reserve button hidden. |
| Time Outside Hours | - (time blocked)                 | Times outside operating hours are grayed and unselectable in the time picker.                |
| Submitting         | Confirm Reservation (disabled)   | Spinner. Cannot double-submit.                                                               |
| Success            | -                                | Confirmation: 'Reservation submitted! You will be notified once staff approves.'             |
| Approved           | -                                | Notification: 'Your reservation at \[time\] has been approved!'                              |
| Declined           | -                                | Notification: 'Sorry, your reservation could not be approved. Please try another time.'      |
| Cancellation       | Cancel Reservation (red outline) | Confirm dialog: 'Cancel your reservation?' On confirm: 'Reservation cancelled.'              |

### 4.5 Customer Dashboard (Logged In)

- Stamp Card - 3×3 grid visualization (X = filled, O = empty)
- Overflow counter - shows 'You have \[N\] stamps queued for your next card'
- Claim Reward button - active only when all 9 slots are filled
- QR Code display + download button
- Purchase history table with order date, items, total, payment method, feedback button

| **State**             | **Button / Label**            | **What Shows / Behavior**                                                                                   |
| --------------------- | ----------------------------- | ----------------------------------------------------------------------------------------------------------- |
| 0-8 Stamps            | Claim Reward (disabled, gray) | Button grayed out. Tooltip: 'Fill all 9 stamps to unlock your reward.' X and O shown in 3×3 grid.           |
| 9 Stamps (Full)       | Claim Reward (active, green)  | Button turns green and clickable. Pulsing animation to draw attention.                                      |
| Select Reward         | Confirm Reward                | Modal opens with list of reward items (product picker from admin config). Customer must pick one.           |
| No Rewards Configured | Claim Reward (disabled)       | Tooltip: 'Rewards are currently unavailable. Please check with staff in-store.' Button disabled.            |
| Generating Code       | Generating... (disabled)      | Spinner. Prevents double-generation.                                                                        |
| Code Generated        | Download QR                   | Reward QR code + text code displayed. 'Present this to staff in-store to redeem.' Single-use warning shown. |
| Offline Stamp Pending | -                             | Yellow banner: 'You have \[N\] stamp(s) pending sync. They will appear once connected.'                     |

### 4.6 QR Code Page

| **State**        | **Button / Label** | **What Shows / Behavior**                                                                          |
| ---------------- | ------------------ | -------------------------------------------------------------------------------------------------- |
| Logged In        | Download QR        | QR code image displayed prominently. Download button saves as PNG. QR contains loyalty ID.         |
| Guest User       | - (no QR shown)    | Message: 'Create an account to access your loyalty QR code and earn stamps.' CTA: Register button. |
| Download Success | Downloaded ✓       | Button briefly shows checkmark. QR saved to device.                                                |
| Download Failed  | Try Again          | Red toast: 'Download failed. Please try again.'                                                    |

### 4.7 Purchase History

| **State**          | **Button / Label**              | **What Shows / Behavior**                                                                                                     |
| ------------------ | ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Has Orders         | Leave Feedback                  | Table of orders. Each row: date, items, total, payment method, status. 'Leave Feedback' on completed orders without feedback. |
| No Orders Yet      | -                               | Empty state: 'No purchases yet. Your order history will appear here after your first visit.'                                  |
| Feedback Submitted | Feedback Submitted ✓ (disabled) | Button grayed out. Cannot submit feedback twice for same order.                                                               |
| Guest User         | -                               | Page not accessible. Redirect to login: 'Log in to view your purchase history.'                                               |

**Deliverables to finish before next phase**

✓ All customer pages load correctly (public and authenticated)

✓ Reservation flow works end-to-end including guest and logged-in paths

✓ Time picker respects operating hours from admin config

✓ 3×3 stamp grid renders correctly with X/O states and overflow counter

✓ Claim reward flow opens reward list modal and generates unique QR + text code

✓ QR code page shows code and download works as PNG

✓ Purchase history shows orders with payment method column

✓ Seat vacancy shows live text count - no seat map visible to customers

✓ Google Maps café location embed loads on landing page

✓ Offline stamp pending banner shows when stamps are queued

**[x] PHASE 5: UI/UX POLISH & ERROR HANDLING Button states · Error messages · Loading states · Toast system · Empty states · Offline indicators**

## Goals for Phase 5

This phase is dedicated to making the system feel professional and trustworthy. Every action must have clear feedback. Users should never be confused about what happened. Build these states inline during Phases 3 and 4, then do a dedicated cleanup pass here.

### 5.1 Global Button State Rules

Apply these rules to EVERY button across the entire system:

| **State**                    | **Visual Treatment**                                                                          |
| ---------------------------- | --------------------------------------------------------------------------------------------- |
| Default / Idle               | Solid fill color (primary: blue, danger: red, success: green). Full opacity. Cursor: pointer. |
| Hover                        | Slightly darker shade. Smooth 150ms transition. Cursor remains pointer.                       |
| Loading / Submitting         | Button disabled. Spinner replaces or precedes text. Opacity 0.8. Cursor: not-allowed.         |
| Disabled (waiting for input) | Gray fill OR low opacity (0.5). Cursor: not-allowed. No hover effect. Tooltip if helpful.     |
| Success (brief)              | Button briefly turns green with checkmark ✓ for 1.5 seconds, then resets.                    |
| Error (persistent)           | Button returns to default. Error shown separately (toast or inline).                          |

### 5.2 Additional UI States

**\[ADDED\] Order type selector UI state (FR S3)**

When staff create a new order, a clear order type selector must appear before items are added.

Options: \[Dine-In\] \[Take-Out\] - pill toggle or segmented control.

Default: Dine-In. Selection is required before the order can proceed.

Order type label shown on the active order summary throughout the session.

**\[ADDED\] Pay-now vs pay-later selector UI state (FR S3, FR S5)**

After order type is selected, staff must choose payment timing.

Options: \[Pay Now\] \[Pay Later\] - pill toggle.

Pay Later: order is saved as open. Staff see it in the open orders list.

Pay Now: payment screen opens immediately after order is confirmed.

**\[ADDED\] Cash change display UI state (FR S5)**

When payment_method = Cash, the payment screen must show:

\- Amount Due: ₱ \[total\]

\- Amount Tendered: \[input field - staff enters cash received\]

\- Change Due: ₱ \[computed automatically as tendered − total\]

Change Due updates in real-time as staff types the tendered amount.

Pay button disabled until tendered amount ≥ total.

**\[ADDED\] No-show notification UI state (FR S1)**

When a reserved customer has not arrived past their time slot, the system sends a notification.

Notification type: Warning (orange/yellow, ⚠ icon).

Message: '\[Customer name\] has not arrived for their \[time\] reservation. Mark seat as free?'

Action button in notification: 'Free Seat' - triggers PUT /api/staff/seats/:id with status=available.

Applies to the staff mobile app notification panel.

**\[ADDED\] ML Loading State**

When ML results are being fetched: skeleton chart placeholder with 'Loading predictions...' label.

**\[ADDED\] ML Force Refresh**

Button in Reports: 'Refresh Predictions' - shows spinner while ML reruns, then updates charts.

### 5.3 Toast Notification System

| **Toast Type**      | **When to Use**                                                                                             |
| ------------------- | ----------------------------------------------------------------------------------------------------------- |
| Success (green, ✓)  | Form saved, account created, payment processed, reservation confirmed, stamp credited, ML refresh complete. |
| Error (red, ✗)      | API errors, failed saves, invalid actions (e.g., trying to claim with < 9 stamps).                         |
| Warning (orange, ⚠) | Low stock alerts, offline stamp pending, no-show notification, pay-later order open, ML restock alert.      |
| Info (blue, ℹ)      | Sync complete, reservation pending approval, ML predictions unavailable (fallback active).                  |

### 5.4 Form Validation Rules

- Validate on submit first, then on blur - never on every keystroke for errors
- Required field missing → 'This field is required.'
- Invalid email format → 'Please enter a valid email address.'
- Price not a number → 'Please enter a valid price (e.g., 120 or 120.50).'
- Password too short → 'Password must be at least 8 characters.'
- Guest count out of range → 'Number of guests must be between 1 and 10.'
- Stock quantity negative → 'Quantity cannot be negative.'
- Cash tendered less than total → 'Amount tendered must be equal to or greater than the total.'
- Reservation time outside operating hours → 'Please select a time within operating hours.'
- Show errors inline below each field in red. Never show all errors in a single red box at the top.

### 5.5 Loading States - Every Page and List

- Initial page load → show skeleton loader (gray animated blocks matching the layout)
- Table data loading → show skeleton rows (3-5 rows of gray animated lines)
- Charts loading → placeholder card with spinning animation
- ML predictions loading → skeleton chart with 'Loading predictions...'
- QR code loading → gray placeholder square with spinner in center
- Never show blank white space - always show a loading indicator

### 5.6 Empty States

- Products list, no products → icon + 'No products yet. Click Add Product to get started.'
- Order history, no orders → icon + 'No orders found for this period.'
- Feedback section, no feedback → icon + 'No customer feedback yet.'
- Notifications, none → 'You are all caught up!'
- Reservation list, none → 'No reservations for this date.'
- Open orders list, none → 'No open pay-later orders right now.'
- ML data - no history → 'Not enough sales data yet. Predictions will appear after 14+ days of sales.'
- Every empty state should have: illustration/icon, short message, optional CTA button if action is available.

### 5.7 Offline Indicator (Web Portal)

- Sticky banner at top of page when browser loses internet connection
- Yellow/orange background: 'You are offline. Some features may not be available.'
- Auto-disappears when connection is restored with green flash: 'Back online!'
- Reservation button disabled when offline with tooltip: 'Internet required to make reservations.'

### 5.8 Confirmation Dialogs - When to Use Them

| **Action**                                       | **Needs Confirm Dialog?**                                                             |
| ------------------------------------------------ | ------------------------------------------------------------------------------------- |
| Delete a product                                 | YES - 'This will remove the product permanently.'                                     |
| Deactivate an employee                           | YES - 'This will prevent the employee from logging in.'                               |
| Cancel a reservation (customer)                  | YES - 'Are you sure you want to cancel?'                                              |
| Claim a reward (customer)                        | YES - 'Confirm reward selection. This action cannot be undone.'                       |
| Change operating hours with pending reservations | YES - 'There are \[N\] pending reservations. Changing hours may affect them.'         |
| Adjust inventory                                 | NO - Just a form modal, no extra confirm needed                                       |
| Toggle stamp eligibility / reward item           | NO - Instant toggle is fine, can be toggled back                                      |
| Mark order as paid                               | NO - Direct action, no confirm needed                                                 |
| Free a no-show seat                              | NO - Action comes from notification, single tap is fine                               |
| Force refresh ML predictions                     | NO - Just runs, shows spinner                                                         |

### 5.9 Network / API Error Handling

| **HTTP Status**           | **User-Facing Message**                                                               |
| ------------------------- | ------------------------------------------------------------------------------------- |
| 400 Bad Request           | Inline validation error based on error code. Show below the relevant field.           |
| 401 Unauthorized          | Redirect to login. Toast: 'Your session has expired. Please log in again.'            |
| 403 Forbidden             | Toast: 'You do not have permission to perform this action.'                           |
| 404 Not Found             | Toast: 'The requested item could not be found. It may have been deleted.'             |
| 409 Conflict              | Inline error relevant to the conflict (e.g., duplicate email, full reservation slot). |
| 422 Unprocessable         | Show inline field errors from the API response.                                       |
| 500 Server Error          | Toast: 'Something went wrong on our end. Please try again in a moment.'               |
| ML Service Down           | Info banner: 'ML predictions temporarily unavailable. Showing basic data.'            |
| Network Timeout / Offline | Toast: 'Could not connect. Please check your internet connection.'                    |

**[/] PHASE 6: INTEGRATION & TESTING End-to-end tests · ML tests · Security audit · Cross-browser · Performance**

## Goals for Phase 6

No feature is done until it is tested end-to-end. This phase covers all integration testing including ML scenarios before deployment.

### 6.1 Integration Test Scenarios - Web + Backend

| **Scenario**                                  | **What to Verify**                                                  |
| --------------------------------------------- | ------------------------------------------------------------------- |
| Admin logs in and creates a product           | Product appears on customer portal immediately                      |
| Admin marks product as reward item            | Reward appears in customer claim modal                              |
| Admin updates operating hours                 | Customer reservation time picker reflects new hours immediately     |
| Admin downloads APK                           | File downloads; staff token returns 403                             |
| Customer makes a reservation with time picker | Staff sees reservation with correct time; no fixed slot required    |
| Two reservations at similar time              | Staff reservation list shows overlap flag on both                   |
| Staff approves reservation                    | Customer notified; seat count updates on portal                     |
| Staff marks no-show                           | Seat freed; count updates; no-show notification cleared             |
| Staff creates pay-later order                 | Order in GET /api/staff/orders?status=open; inventory deducted      |
| Staff collects cash payment                   | change_due computed; receipt issued; order off open list            |
| Staff collects GCash payment                  | payment_method=GCash stored; change_due=0; receipt issued           |
| Customer earns exactly 9 stamps               | All 9 slots fill; no excess; claim button activates                 |
| Customer earns 12 stamps                      | 9 slots fill; 3 queued; claim button active                         |
| Customer claims with 3 excess                 | Card resets; fills with 3 stamps; reward code marked used           |
| Customer earns 14 stamps (overflow carry)     | 9 slots fill; 5 queued → claim → card resets → fills with 5 stamps  |
| Admin views reports - ML active               | Best seller badges show; forecast chart renders; restock days shown |
| Admin views reports - < 14 days data          | 'Not enough data yet' message shown correctly                       |
| ML service stopped during report load         | Fallback data shown; info banner displayed; no crash                |
| Admin clicks Force Refresh                    | ML cache cleared; new predictions fetched; charts update            |
| Admin refunds stamped order                   | Stamps deducted; inventory restored; refund logged                  |
| Admin deletes product with pending orders     | Error returned; product not deleted                                 |

### 6.2 ML-Specific Test Cases

| **ML Test**                       | **Expected Result**                                                          |
| --------------------------------- | ---------------------------------------------------------------------------- |
| 0 days of sales data              | All three ML endpoints return { status: 'insufficient_data' }                |
| 13 days of data                   | Forecast returns insufficient_data; restock and classify return basic results|
| 14 days of data                   | Forecast returns 7-day prediction; all features active                       |
| 30 days of data                   | K-Means classification returns 3 labeled groups                              |
| Product with 0 sales in 30 days   | Correctly classified as Slow Mover                                           |
| Inventory item consumed > stock   | days_remaining = 0; Restock Now label; notification triggered                |
| ML result cached - second request | Result returns from ml_results table; no ML service call made                |
| Cache expired (24hrs passed)      | ML service called again; fresh result returned and cached                    |
| Force Refresh clicked             | Cache cleared; ML called immediately; updated result stored                  |
| ML service unreachable            | Fallback data returned; info banner shown; no 500 error                      |

### 6.3 Security Checklist

- Admin routes reject customer and staff tokens (403)
- Customer routes reject admin and staff tokens
- All inputs sanitized - no SQL injection, no XSS through product names or CMS content
- Reward codes are truly single-use - second redemption attempt returns error
- Passwords hashed (bcrypt) - never stored or returned in plain text
- JWT expiry enforced - expired tokens return 401
- GET /api/admin/apk/download returns 403 for staff and customer tokens
- GET /api/staff/members?search= returns 403 for customer and guest tokens
- ML service endpoints unreachable from public internet - internal only
- Pay endpoint rejects amount_tendered < total for cash payments

### 6.4 Cross-Browser Testing

- Chrome (latest), Firefox (latest), Safari (latest), Edge
- Mobile browser: Chrome on Android, Safari on iOS (for customer portal)
- Test at: 1920px (desktop), 1280px (laptop), 768px (tablet), 390px (mobile)

**[ ] PHASE 7: DEPLOYMENT & HANDOVER TO MOBILE DEV Production setup · Documentation · SQLite schema · Mobile API handover**

### 7.1 Deployment Checklist

- Backend deployed to production server (VPS or cloud)
- ML service deployed alongside backend (same server, port 5001)
- Database migrations run on production
- Environment variables set for production (never commit .env to Git)
- HTTPS enabled - all endpoints over SSL
- Customer portal and Admin panel deployed to web hosting
- Admin account created for the café owner
- Seed data: products, categories, initial inventory, operating hours (5PM-12AM)
- ML service health check passes: GET /ml/health returns { status: 'ok' }

### 7.2 Documentation for Mobile Developer

- Full Postman collection exported and shared
- API endpoint list with sample request/response for every endpoint
- Authentication flow: how to get a staff JWT, token format, expiry
- Offline sync: which endpoints mobile calls on reconnect
- Stamp credit endpoint: request body, QR format, offline queue behavior
- Order creation: all required fields for dine-in/take-out and pay-now/pay-later
- Payment endpoint: payment_method values, amount_tendered, change_due response
- Open orders endpoint: GET /api/staff/orders?status=open and response shape
- Member search endpoint: GET /api/staff/members?search= and response shape
- Operating hours endpoint: GET /api/admin/operating-hours - mobile uses this to validate reservation times

**\[ADDED\] SQLite local schema for mobile developer (NFR 8)**

Provide /docs/mobile-sqlite-schema.md with the following local tables:

\- orders (id, type, payment_timing, status, items_json, total, created_at, synced)

\- order_items (id, order_id, product_id, qty, price)

\- inventory_cache (product_id, current_stock, last_synced_at) - read-only cache

\- stamps_queue (id, customer_id, order_id, qty, created_at, synced)

\- sync_logs (id, table_name, record_id, operation, payload, synced_at, conflict)

Conflict resolution rule (server always wins):

1\. On reconnect, push local data to server first.

2\. If server rejects or has a newer version, overwrite the local record.

3\. Log conflict to sync_logs with conflict=true for admin review.

4\. Never merge - always replace with server version.

### 7.3 Handover Note to Mobile Developer

The mobile POS app (Android APK) will need the following backend features that are already built:

- POST /api/staff/orders - create order (offline: queue in SQLite, sync on reconnect)
- GET /api/staff/orders?status=open - retrieve open pay-later orders
- POST /api/staff/orders/:id/pay - process payment (payment_method, amount_tendered; returns change_due)
- POST /api/staff/stamps/credit - credit stamps (offline: queue scan, sync on reconnect)
- GET /api/staff/members?search= - search customer accounts for member list lookup
- POST /api/staff/rewards/redeem - redeem reward code (requires internet)
- PUT /api/staff/seats/:id - toggle seat state (requires internet for live sync)
- GET /api/staff/reservations - list reservations sorted by time with overlap flag
- PUT /api/staff/reservations/:id - approve/decline (requires internet)
- POST /api/staff/orders/:id/refund - process refund (requires internet)
- GET /api/admin/operating-hours - get opening/closing time for reservation validation

**ML service is NOT needed by the mobile app - ML results are admin web panel only.**

The mobile developer should use the same JWT auth system. Staff tokens are scoped to /api/staff/\* routes only.

# Quick Reference: Phase Summary

| **Phase**                  | **Who Does What + Key Output**                                                                                                                                                                                                                                                               |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Phase 1 Setup & Foundation | Backend: DB schema (payment columns + ml_results table), migrations, JWT auth, SQLite schema stub. Frontend: Project init, route shells, component stubs, API wrapper. Output: Runnable project, login returns JWT, all routes exist                                                          |
| Phase 2 Core Backend API   | Backend: ALL endpoints - auth, products, inventory, orders (pay-later + cash change), stamps (member search), reservations, CMS, reports, APK download, operating hours. Frontend: Postman testing only, mock data. Output: Full API works in Postman, seeded with test data                 |
| Phase 2.5 ML Service (NEW) | Backend: Python Flask ML microservice with Prophet forecasting, K-Means classification, moving average restock prediction, 24hr caching, fallback handling. Output: /ml/health passes, all 3 ML endpoints return correct results, cache and fallback both work                               |
| Phase 3 Admin Panel        | Frontend: All admin UI including ML results in reports, restock predictions in inventory, operating hours config, overlap flag in reservations, APK download. Backend: Fix API issues, ML integration. Output: Admin can configure system and view ML-powered reports                        |
| Phase 4 Customer Portal    | Frontend: All customer UI - time picker respects operating hours, reward list from product toggles, payment method in history. Output: Customer can reserve, earn stamps, claim rewards, view history                                                                                        |
| Phase 5 UI/UX Polish       | Frontend: All button states, toasts, loading skeletons, empty states, ML loading state, ML unavailable banner, force refresh button. Output: Every action has feedback, ML states handled gracefully                                                                                         |
| Phase 6 Testing            | Both: Integration tests including ML scenarios, cold start tests, cache tests, fallback tests, security audit, cross-browser. Output: All scenarios pass including full ML test suite                                                                                                        |
| Phase 7 Deployment         | Both: Deploy backend + ML service to production, write mobile handover docs with SQLite schema and conflict rules. Output: System live, ML running, API documented for mobile developer                                                                                                      |

**Golden Rules for the Developer Team**

1\. Never build frontend without a confirmed API contract - it will be wrong and cause rework.

2\. Every button must have a loading state - users click twice if they see no response.

3\. Every error must have a user-readable message - error codes are for developers, not users.

4\. Test the stamp overflow logic thoroughly - 9 stamps is the most complex business logic in this system.

Test cases: exactly 9, overflow with carry-over, claim and reset, stamp on just-claimed card.

5\. The Admin Panel is the most important panel to finish first - nothing works until the admin configures it.

6\. Build security from the start - role checks on every route from Phase 2, not as an afterthought.

7\. Store payment_method on every transaction - reports and history depend on it.

8\. Document the SQLite schema and conflict resolution rule for the mobile developer before handover.

9\. ML service must always have a fallback - reports page must never break if ML is down.

10\. ML needs data - show 'Not enough data yet' gracefully for new installs.

_- End of Document -_