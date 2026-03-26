**CUTshier**

POS & Inventory Management System

_for Cutsy Coffee_

**DEVELOPER TEAM - DEVELOPMENT PHASES GUIDE Web (Customer Portal + Admin Panel) & Backend API - Focus Track**

Version 1.1 (Updated) | BS Computer Science - CS17/L Software Engineering | UM Tagum College

# Overview: Why Web + Backend First?

This guide covers the phased development plan for CUTshier when the team prioritizes the Web platforms (Customer Portal + Admin Web Panel) and the Backend API before starting on the Mobile POS app. This is the recommended approach because:

- The Backend API is the core foundation - both the web and mobile depend on it.
- The Admin Panel lets the owner configure products, inventory, and time slots before any other feature is usable.
- The Customer Portal is web-only and has zero dependency on mobile - it can ship independently.
- Building web + backend first lets the team validate all business logic before the Android app is built.

Team Structure (Recommended Split)

Backend Developer - API, database, authentication, business logic, sync engine

Frontend Developer (Web) - Customer portal, Admin panel, UI/UX, component states

Shared responsibility - Integration testing, API contracts, error handling, documentation

## Overall Phase Timeline

| **Phase**                               | **Focus Area**                                                |
| --------------------------------------- | ------------------------------------------------------------- |
| Phase 1 - Setup & Foundation            | Project scaffolding, DB schema, auth, dev environment         |
| Phase 2 - Core Backend API              | All REST endpoints, business logic, offline sync prep         |
| Phase 3 - Admin Web Panel               | Full admin UI: products, inventory, employees, CMS, reports   |
| Phase 4 - Customer Web Portal           | Customer UI: menu, reservations, loyalty stamps, QR code      |
| Phase 5 - UI/UX Polish & Error Handling | All button states, error messages, loading states, edge cases |
| Phase 6 - Integration & Testing         | End-to-end testing, API validation, cross-browser, security   |
| Phase 7 - Deployment & Handover         | Production setup, documentation, mobile prep handover         |

**PHASE 1: SETUP & FOUNDATION Project scaffolding · Database schema · Authentication · Dev environment**

## Goals for Phase 1

Before writing a single feature, the entire team must agree on architecture, set up their local environments, and establish the database - because changing the schema mid-project causes major rework.

### 1.1 Backend Developer - Start Here

- Initialize the backend project (Node.js/Express or Laravel - team decides)
- Set up PostgreSQL (or MySQL) database on local and dev server
- Design and finalize the full database schema:
- Tables: users, employees, products, categories, inventory, orders, order_items, transactions, stamps, reservations, seats, time_slots, rewards, reward_codes, feedback, notifications, sync_logs
- transactions table must include: payment_method (Cash | GCash | Maya), amount_tendered, change_due columns - required for FR S5
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
- Create reusable component library stubs: Button, Input, Modal, Toast, Badge, Table, Card
- Set up Axios or Fetch wrapper for all API calls with global error interceptor
- Set up React Router with protected routes (role-based guards)
- Create placeholder pages for all major screens - no logic yet, just route shells

### 1.3 Shared / Both Developers

- Agree on API contract format: RESTful JSON, consistent response envelope
- Define standard API response format (see box below)
- Set up Postman collection for all planned endpoints
- Agree on error code conventions

Standard API Response Envelope - Agree on This First

Success: { success: true, data: { ... }, message: 'OK' }

Error: { success: false, error: { code: 'INVALID_CREDENTIALS', message: 'Email or password is incorrect.' } }

List: { success: true, data: \[ ... \], meta: { total: 50, page: 1, limit: 20 } }

All API responses must follow this format. Never return raw data without the envelope.

Error codes must be SCREAMING_SNAKE_CASE strings - the frontend maps these to user-friendly messages.

**Deliverables to finish before next phase**

✓ Git repo initialized, all developers can clone and run locally

✓ Database migrations run successfully on local (including payment_method, amount_tendered, change_due columns)

✓ JWT auth returns a valid token on POST /api/auth/login

✓ All route shells exist in the frontend (even if blank pages)

✓ Postman collection created with all planned endpoint names

✓ .env.example committed to repo with all required keys documented

✓ SQLite schema stub document created and saved to /docs/mobile-sqlite-schema.md

**PHASE 2: CORE BACKEND API All REST endpoints · Business logic · Validation · Sync engine setup**

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
- GET /api/staff/members?search= - search customer accounts by name or email for member list lookup on handheld device
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

- GET /api/reservations/slots - public endpoint: available time slots with seat count
- POST /api/reservations - create reservation (logged-in or guest with name/contact)
- GET /api/staff/reservations - list all pending/approved reservations
- PUT /api/staff/reservations/:id - approve or decline
- DELETE /api/reservations/:id - customer cancels their own reservation
- POST /api/staff/seats/:id/free - mark no-show seat as free
- Auto-notify: trigger notification on approval/decline/cancellation/no-show warning

### 2.7 Seat Map API

- GET /api/seats - current state of all seats (Available, Occupied, Reserved)
- PUT /api/staff/seats/:id - toggle Available/Occupied
- Auto-shift: reserved seat auto-becomes Occupied when time slot begins (cron job or scheduled check)
- Seat vacancy count: computed field returned on GET /api/seats/count - used by customer portal

### 2.8 Admin Panel APIs

- GET/PUT /api/admin/employees - manage staff accounts
- GET /api/admin/reports/sales - daily/monthly sales reports (filterable by date, payment_method)
- GET /api/admin/reports/products - best-selling and slow-moving products
- GET /api/admin/reports/inventory - depletion analysis and restock predictions
- GET/POST/PUT/DELETE /api/admin/cms - banners, announcements, promos
- GET/POST/PUT/DELETE /api/admin/time-slots - reservation operating hours config
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
- Internal triggers: low-stock, reservation approval/decline/cancel, refund, sync complete, no-show warning

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

✓ Inventory auto-deduct works when an order is placed

✓ Inventory auto-restore works on void and on refund

✓ Postman collection is fully up to date and shareable with frontend dev

✓ Seed data exists: at least 10 products, 3 categories, 1 admin, 1 staff, 1 customer

**PHASE 3: ADMIN WEB PANEL Full admin UI: products · inventory · employees · CMS · reports · seat overview · APK download**

## Goals for Phase 3

Build the complete Admin Web Panel. The admin is the first real user of the system - they configure products, inventory, and time slots before customers or staff can do anything. The frontend developer should connect to the live backend from Phase 2.

### 3.1 Admin Login Page

| **Screen Element** | **Details**                                                                                                   |
| ------------------ | ------------------------------------------------------------------------------------------------------------- |
| Route              | /admin/login                                                                                                  |
| Fields             | Email, Password                                                                                               |
| Login Button       | Disabled while fields are empty; shows spinner on submit                                                      |
| Error Handling     | Wrong credentials → red toast: 'Incorrect email or password.'                                                 |
| Redirect           | On success → /admin/dashboard                                                                                 |
| Guard              | If already logged in, redirect to dashboard; staff login on this page returns 'You do not have admin access.' |

### 3.2 Dashboard

- Summary cards: Today's Sales, Orders Today, Low Stock Alerts count, Pending Reservations
- Quick links: Go to Reports, View Inventory, Manage Reservations
- Notification bell icon in header - badge count of unread notifications

### 3.3 Product Management

- Table listing all products with: Name, Category, Price, Availability toggle, Stamp Eligible toggle
- Add Product button → opens modal/drawer with form
- Edit / Delete actions per row
- Stamp Eligible toggle - inline toggle switch per product row
- Reward Items section - separate list of claimable reward items with add/edit/delete

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

- Table: Product name, Current Stock, Minimum Threshold, Last Updated, Adjust button
- Highlight rows in red when stock is at or below minimum threshold
- Adjustment modal: reason dropdown (Restock, Damaged, Incorrect Count), quantity field, notes

| **State**       | **Button / Label**   | **What Shows / Behavior**                                                                                    |
| --------------- | -------------------- | ------------------------------------------------------------------------------------------------------------ |
| Idle            | Adjust Stock         | Button active. Reason and quantity required.                                                                 |
| Saving          | Saving... (disabled) | Spinner. Inputs locked.                                                                                      |
| Success         | Adjust Stock         | Green toast: 'Inventory updated.' Table row refreshes with new value.                                        |
| Low Stock Alert | - (auto)             | Row highlighted red. Orange badge 'LOW' in stock column. Notification sent to admin.                         |
| Zero Stock      | - (auto)             | Row highlighted dark red. Badge 'OUT OF STOCK'. Product automatically marked unavailable on customer portal. |

### 3.5 Employee Management

- List of staff accounts with name, role, status (Active/Inactive)
- Create Employee - generates credentials for mobile POS login
- Deactivate / Reactivate toggle per employee

| **State**       | **Button / Label**  | **What Shows / Behavior**                                                                                                                           |
| --------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Create Employee | Create Account      | Form: Name, Email, Role. On success: green toast 'Account created. Credentials sent.' If email exists: 'An account with this email already exists.' |
| Deactivate      | Deactivate (orange) | Confirm dialog: 'This will prevent the employee from logging in.' On confirm: status changes to Inactive, row grays out.                            |
| Reactivate      | Reactivate (green)  | No confirmation needed. Status changes to Active immediately.                                                                                       |

### 3.6 Reservation Management (Admin - Read Only)

- Calendar or list view of all reservations: date, time slot, customer name, guests, status
- Admin can view only - no approve/decline actions (staff do that in the mobile app)
- Filter by date range and status

### 3.7 Seat Overview (Admin - Read Only)

- Visual grid showing all seats with color coding: Green = Available, Red = Occupied, Blue = Reserved
- Reserved seats show tooltip: customer name (or "Guest"), time slot, guest count
- Note displayed: 'Seat state is managed by staff on the mobile app.'

### 3.8 Time Slot Configuration

- List of configured time slots (e.g., 5:00 PM, 6:00 PM... 11:00 PM)
- Add / Remove time slot buttons
- Warning when removing a time slot that has pending reservations

**\[ADDED\] Default time slots on first run (FR A - Time Slots)**

On first login, the time slot configuration page must be pre-populated with the default operating hours.

Default slots: 5:00 PM, 6:00 PM, 7:00 PM, 8:00 PM, 9:00 PM, 10:00 PM, 11:00 PM, 12:00 AM.

Show a banner: 'These are the default operating hours. Edit or remove slots as needed.'

Admin must be able to modify before any reservations go live.

### 3.9 Reports & Analytics

- Sales Report: date range picker, chart (bar/line), table with daily totals, export to PDF/CSV
- Sales report table must include payment method breakdown (Cash, GCash, Maya totals per day)
- Product Analysis: best-selling table, least-selling table, predicted demand for next 7/30 days
- Inventory Analysis: depletion rate per product, projected out-of-stock dates
- Feedback Viewer: star rating averages per product, recent reviews list

### 3.10 CMS - Content Management

- Banners: upload image + caption, toggle active/inactive, preview
- Announcements: rich text editor for short announcements shown on customer portal
- Promos: title, description, image, start/end date
- All CMS changes reflect immediately on the customer portal

### 3.11 APK Download

**\[ADDED\] APK download screen (FR A11) - was missing, now added**

Section in admin sidebar: Settings > POS App Download

Displays: current APK version, file size, last updated date

Button: "Download POS App (APK)" - calls GET /api/admin/apk/download

Instructions shown: "Install this APK on the staff Android handheld device."

Only visible to admin - staff accounts do not see this section.

**Deliverables to finish before next phase**

✓ Admin can log in and access all sections

✓ Product CRUD works end-to-end including stamp eligibility toggle

✓ Reward items section uses product picker - not free-text form

✓ Inventory adjustments persist and low-stock alerts trigger correctly

✓ Reports load real data including payment method breakdown

✓ Time slot config page pre-populated with default 5PM-12AM slots on first run

✓ APK download section visible and functional for admin only

✓ CMS content published by admin appears on the customer portal

✓ All button states and error messages implemented

✓ **SOLID Backend Refactor:** Isolated DB logic into repositories for all Phase 3 domains.

**PHASE 4: CUSTOMER WEB PORTAL Menu · Seat vacancy · Reservations · Loyalty stamps · QR code · Purchase history**

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
- Step 2: Select Time Slot - only show slots with available seats
- Step 3: Enter Guest Count (1-10) and Name/Contact (for guest users)
- Step 4: Review and Confirm
- Step 5: Confirmation screen - reservation pending staff approval

| **State**          | **Button / Label**               | **What Shows / Behavior**                                                                         |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------------------------------- |
| No Slots Available | - (no slots shown)               | Message: 'No available time slots for this date. Please try another date.' Reserve button hidden. |
| Slot Full          | - (slot grayed out)              | Grayed time slot chip with label '(Full)'. Cannot be selected.                                    |
| Submitting         | Confirm Reservation (disabled)   | Spinner. Cannot double-submit.                                                                    |
| Success            | -                                | Confirmation screen: 'Reservation submitted! You will be notified once staff approves.'           |
| Approved           | -                                | Notification: 'Your reservation for \[date\] at \[time\] has been approved!'                      |
| Declined           | -                                | Notification: 'Sorry, your reservation could not be approved. Please try another slot.'           |
| Cancellation       | Cancel Reservation (red outline) | Confirm dialog: 'Are you sure you want to cancel?' On confirm: 'Reservation cancelled.'           |

### 4.5 Customer Dashboard (Logged In)

- Stamp Card - 3×3 grid visualization (X = filled, O = empty)
- Overflow counter - shows 'You have \[N\] stamps queued for your next card'
- Claim Reward button - active only when all 9 slots are filled
- QR Code display + download button
- Purchase history table with order date, items, total, feedback button

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

✓ 3×3 stamp grid renders correctly with X/O states and overflow counter

✓ Claim reward flow opens reward list modal and generates unique QR + text code

✓ QR code page shows code and download works as PNG

✓ Purchase history shows orders with payment method column

✓ Seat vacancy shows live text count - no seat map visible to customers

✓ Google Maps café location embed loads on landing page

✓ Offline stamp pending banner shows when stamps are queued

**PHASE 5: UI/UX POLISH & ERROR HANDLING Button states · Error messages · Loading states · Toast system · Empty states · Offline indicators**

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
| Success (brief)              | Button briefly turns green with checkmark ✓ for 1.5 seconds, then resets.                     |
| Error (persistent)           | Button returns to default. Error shown separately (toast or inline).                          |

### 5.2 Additional UI States - Added

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

### 5.3 Toast Notification System

| **Toast Type**      | **When to Use**                                                                        |
| ------------------- | -------------------------------------------------------------------------------------- |
| Success (green, ✓)  | Form saved, account created, payment processed, reservation confirmed, stamp credited. |
| Error (red, ✗)      | API errors, failed saves, invalid actions (e.g., trying to claim with < 9 stamps).     |
| Warning (orange, ⚠) | Low stock alerts, offline stamp pending, no-show notification, pay-later order open.   |
| Info (blue, ℹ)      | Neutral status: 'Sync complete', 'Reservation pending approval'.                       |

### 5.4 Form Validation Rules

- Validate on submit first, then on blur - never on every keystroke for errors
- Required field missing → 'This field is required.'
- Invalid email format → 'Please enter a valid email address.'
- Price not a number → 'Please enter a valid price (e.g., 120 or 120.50).'
- Password too short → 'Password must be at least 8 characters.'
- Guest count out of range → 'Number of guests must be between 1 and 10.'
- Stock quantity negative → 'Quantity cannot be negative.'
- Cash tendered less than total → 'Amount tendered must be equal to or greater than the total.'
- Show errors inline below each field in red. Never show all errors in a single red box at the top.

### 5.5 Loading States - Every Page and List

- Initial page load → show skeleton loader (gray animated blocks matching the layout)
- Table data loading → show skeleton rows (3-5 rows of gray animated lines)
- Charts loading → placeholder card with spinning animation
- QR code loading → gray placeholder square with spinner in center
- Never show blank white space - always show a loading indicator

### 5.6 Empty States

- Products list, no products → icon + 'No products yet. Click Add Product to get started.'
- Order history, no orders → icon + 'No orders found for this period.'
- Feedback section, no feedback → icon + 'No customer feedback yet.'
- Notifications, none → 'You are all caught up!'
- Reservation list, none → 'No reservations for this date.'
- Open orders list, none → 'No open pay-later orders right now.'
- Every empty state should have: illustration/icon, short message, optional CTA button if action is available.

### 5.7 Offline Indicator (Web Portal)

- Sticky banner at top of page when browser loses internet connection
- Yellow/orange background: 'You are offline. Some features may not be available.'
- Auto-disappears when connection is restored with green flash: 'Back online!'
- Reservation button disabled when offline with tooltip: 'Internet required to make reservations.'

### 5.8 Confirmation Dialogs - When to Use Them

| **Action**                                   | **Needs Confirm Dialog?**                                                |
| -------------------------------------------- | ------------------------------------------------------------------------ |
| Delete a product                             | YES - 'This will remove the product permanently.'                        |
| Deactivate an employee                       | YES - 'This will prevent the employee from logging in.'                  |
| Cancel a reservation (customer)              | YES - 'Are you sure you want to cancel?'                                 |
| Claim a reward (customer)                    | YES - 'Confirm reward selection. This action cannot be undone.'          |
| Remove a time slot with pending reservations | YES - Show warning: 'There are \[N\] pending reservations in this slot.' |
| Adjust inventory                             | NO - Just a form modal, no extra confirm needed                          |
| Toggle stamp eligibility                     | NO - Instant toggle is fine, can be toggled back                         |
| Mark order as paid                           | NO - Direct action, no confirm needed                                    |
| Free a no-show seat                          | NO - Action comes from notification, single tap is fine                  |

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
| Network Timeout / Offline | Toast: 'Could not connect. Please check your internet connection.'                    |

**PHASE 6: INTEGRATION & TESTING End-to-end tests · API validation · Cross-browser · Security audit · Performance**

## Goals for Phase 6

No feature is done until it is tested end-to-end. This phase covers all integration testing before deployment.

### 6.1 Integration Test Scenarios - Web + Backend

| **Scenario**                                         | **What to Verify**                                                                 |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Admin logs in and creates a product                  | Product appears on customer portal menu immediately                                |
| Admin marks product as stamp-eligible                | Stamp eligible flag visible in staff API response                                  |
| Admin configures a reward item (product picker)      | Reward appears in customer claim flow modal                                        |
| Admin adds and removes a time slot                   | Slot appears/disappears on reservation page; warning shown if pending reservations |
| Admin downloads APK                                  | APK file downloads successfully; staff token returns 403                           |
| Customer creates account and logs in                 | JWT returned, /api/auth/me returns correct profile                                 |
| Customer makes a reservation as guest                | Staff sees reservation with guest name, no account linked                          |
| Staff approves reservation                           | Customer portal shows 'Approved' status, seat count updates                        |
| Staff marks no-show                                  | Seat freed, seat count updates on customer portal, no-show notification cleared    |
| Staff creates pay-later order                        | Order appears in GET /api/staff/orders?status=open; inventory deducted immediately |
| Staff retrieves open order and collects cash payment | change_due computed correctly; receipt issued; order removed from open list        |
| Staff collects GCash payment                         | payment_method=GCash stored; change_due=0; receipt issued                          |
| Customer earns stamps (exactly 9)                    | All 9 slots fill, no excess, claim button activates                                |
| Customer earns 12 stamps (overflow)                  | All 9 slots fill, excess=3 queued, claim button activates                          |
| Customer claims reward with 3 excess                 | Card resets, fills with 3 stamps, reward code marked used                          |
| Customer earns 14 stamps (overflow carry test)       | 9 slots fill, excess=5 queued → claim → card resets → fills with 5 stamps          |
| Admin processes refund on stamped order              | Stamps deducted from customer, inventory restored, refund logged                   |
| Admin deletes product with pending orders            | Correct error returned, product not deleted                                        |

### 6.2 Security Checklist

- Admin routes reject customer and staff tokens (403)
- Customer routes reject admin and staff tokens
- All inputs sanitized - no SQL injection, no XSS through product names or CMS content
- Reward codes are truly single-use - second redemption attempt returns error
- Passwords are hashed (bcrypt) - never stored or returned in plain text
- JWT expiry enforced - expired tokens return 401
- GET /api/admin/apk/download returns 403 for staff and customer tokens
- GET /api/staff/members?search= returns 403 for customer and guest tokens
- Pay endpoint rejects amount_tendered < total for cash payments

### 6.3 Cross-Browser Testing

- Chrome (latest), Firefox (latest), Safari (latest), Edge
- Mobile browser: Chrome on Android, Safari on iOS (for customer portal)
- Test at: 1920px (desktop), 1280px (laptop), 768px (tablet), 390px (mobile)

**PHASE 7: DEPLOYMENT & HANDOVER TO MOBILE DEV Production setup · Documentation · Mobile prep · Handover checklist**

### 7.1 Deployment Checklist

- Backend deployed to production server (VPS or cloud)
- Database migrations run on production
- Environment variables set for production (never commit .env to Git)
- HTTPS enabled - all endpoints over SSL
- Customer portal and Admin panel deployed to web hosting
- Admin account created for the café owner
- Seed data added: products, categories, initial inventory, default time slots (5PM-12AM)

### 7.2 Documentation for Mobile Developer

- Full Postman collection exported and shared
- API endpoint list with sample request/response for every endpoint
- Authentication flow documented: how to get a staff JWT, token format, expiry
- Offline sync API: document which endpoints the mobile app calls on reconnect
- Stamp credit endpoint: document exact request body, QR code format, offline queue behavior
- Order creation endpoint: document all required fields for dine-in/take-out and pay-now/pay-later
- Payment endpoint: document payment_method values, amount_tendered field, change_due response
- Open orders endpoint: document GET /api/staff/orders?status=open and response shape
- Member search endpoint: document GET /api/staff/members?search= and response shape

**\[ADDED\] SQLite local schema for mobile developer (NFR 8)**

Provide /docs/mobile-sqlite-schema.md with the following local tables:

\- orders (id, type, payment_timing, status, items_json, total, created_at, synced)

\- order_items (id, order_id, product_id, qty, price)

\- inventory_cache (product_id, current_stock, last_synced_at) - read-only cache

\- stamps_queue (id, customer_id, order_id, qty, created_at, synced)

\- sync_logs (id, table_name, record_id, operation, payload, synced_at, conflict)

Conflict resolution rule (server always wins):

\- On reconnect, local data is pushed to server first.

\- If server rejects or returns a newer version, local record is overwritten.

\- Conflict is logged to sync_logs with conflict=true for admin review.

\- Never merge - always replace with server version.

### 7.3 Handover Note to Mobile Developer

The mobile POS app (Android APK) will need the following backend features that are already built:

- POST /api/staff/orders - create order (offline: queue in SQLite, sync on reconnect)
- GET /api/staff/orders?status=open - retrieve open pay-later orders
- POST /api/staff/orders/:id/pay - process payment (payment_method, amount_tendered; returns change_due)
- POST /api/staff/stamps/credit - credit stamps (offline: queue scan, sync on reconnect)
- GET /api/staff/members?search= - search customer accounts for member list lookup
- POST /api/staff/rewards/redeem - redeem reward code (requires internet)
- PUT /api/staff/seats/:id - toggle seat state (requires internet for live sync)
- GET /api/staff/reservations - list reservations (requires internet)
- PUT /api/staff/reservations/:id - approve/decline (requires internet)
- POST /api/staff/orders/:id/refund - process refund (requires internet)

The mobile developer should use the same JWT auth system. Staff tokens are scoped to /api/staff/\* routes only.

# Quick Reference: Phase Summary

| **Phase**                    | **Who Does What + Key Output**                                                                                                                                                                                                                                                          |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Phase 1 - Setup & Foundation | Backend: DB schema (with payment_method, change_due columns), migrations, JWT auth, SQLite schema stub Frontend: Project init, route shells, component stubs, API wrapper Output: Runnable project, login returns JWT, all routes exist                                                 |
| Phase 2 - Core Backend API   | Backend: ALL endpoints for auth, products, inventory, orders (with pay-later + cash change), stamps (with member search), reservations, CMS, reports, APK download Frontend: Postman testing only, mock data for early UI work Output: Full API works in Postman, seeded with test data |
| Phase 3 - Admin Panel        | Frontend: All admin UI screens including APK download section, product picker for rewards, default time slots Backend: Fix any API issues found during integration Output: Admin can log in, manage products/inventory/employees, download APK, view reports                            |
| Phase 4 - Customer Portal    | Frontend: All customer UI screens including map embed, reward list modal, pay-method in history Backend: Fix any API issues found during integration Output: Customer can reserve, earn stamps, claim rewards, view history                                                             |
| Phase 5 - UI/UX Polish       | Frontend: All button states, toasts, loading skeletons, empty states, error handling, new UI states (order type, pay timing, cash change, no-show notification) Both: Review and fix all edge cases Output: Every action has feedback, no blank states, offline indicator works         |
| Phase 6 - Testing            | Both: Integration tests (including overflow carry-over test + APK + cash change + pay-later), security audit, cross-browser Output: All scenarios pass, no security holes, works on mobile browsers                                                                                     |
| Phase 7 - Deployment         | Both: Deploy to production, write mobile dev handover docs including SQLite schema and conflict resolution rules Output: System live, API fully documented for mobile developer                                                                                                         |

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

_- End of Document -_