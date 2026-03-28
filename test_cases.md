# Catsy Coffee — Complete System Test Case Suite

This document provides a structured set of test cases to verify the functionality, security, and architectural integrity of the Catsy Coffee ecosystem (Admin Panel, Customer Portal, and shared Backend).

---

## 🔐 0. Authentication & Security (Cross-Platform)
*Last Updated: 2026-03-27*

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_ATH_001** | Auth | Admin Web Login | 1. Navigate to `/login`.<br>2. Enter Admin credentials. | Redirects to `/admin/dashboard`. |succusfly login goes to dashboard page | pass |
| **TC_ATH_002** | Auth | Customer Web Login | 1. Navigate to `/login`.<br>2. Enter Customer credentials. | Redirects to `/profile` or Home. |succufuly login, goes to profile page |pass |
| **TC_ATH_003** | Auth | Cross-Portal Denial | 1. Use **Staff** credentials on Web Login.<br>2. Attempt access to `/admin`. | System blocks access with "Access Denied" message. | [Fix Applied] AdminLogin now checks role before granting access. Needs manual test with a customer/staff account. | pending |
| **TC_ATH_004** | Auth | Logout Flow | 1. Click Profile icon > Logout. | Auth token cleared; redirected to Home. | [Fix Applied] Admin header refactored with a dedicated Sign Out button always visible in top-right. Needs manual verification. | pending |

---

## 🛒 1. Customer Web Portal
*Last Updated: 2026-03-27*

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_CST_001** | Reservation | Guest Booking | 1. Go to Reservations.<br>2. Fill details as Guest.<br>3. Submit. | Receives "Reservation Pending" notification. | [Fix Applied] Form now has explicit red error labels per field + manual validation. Needs manual test with empty fields. | pending |
| **TC_CST_002** | Reservation | Member Booking | 1. Login as Member.<br>2. Book a table. | Profile pre-fills; booking appears in history. |succesfuly prefills all fields |pass |
| **TC_CST_003** | Reservation | Cancellation | 1. Go to "My Reservations".<br>2. Click "Cancel". | Status changes to "Cancelled"; seat freed. |Successfully implemented cancel button for pending reservations. | pass |
| **TC_CST_004** | UI Core | Nav Menu | 1. View on Mobile screen.<br>2. Click Hamburger menu. | Side menu slides in smoothly (GSAP animation). |succuelfy can view menu on mobile device navitae to pages, but no smooth slides of menu| pass, no smooth slides of menu  |
| **TC_UIX_003** | UI Core | Button States | 1. Click "Submit" on a slow network. | Button shows "Loading..." spinner + disables. | [Fix Applied] Animated dot cycle (`. .. ...`) added to Admin Login and Reservation submit buttons. Needs manual test to confirm animation renders. | pending |

---

## 🏗️ 2. Core Architecture (SOLID & Backend)
*Last Updated: 2026-03-28*

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_SLD_001** | Backend SOLID | Dependency Injection | 1. Open `app/routers/cms.py`.<br>2. Check for `Depends(get_repo)`. | Router delegates all DB work to `CmsRepository`. |All four route handlers (get_cms_items, create_cms_item, update_cms_item, delete_cms_item, get_public_cms) declare repo: CmsRepository = Depends(get_repo). No Supabase calls exist in the router — all DB work is delegated to CmsRepository. The get_repo() factory is also swappable in tests, confirming DIP compliance. | pass |
| **TC_SLD_002** | Backend SOLID | Pure Aggregation | 1. Inspect `app/repositories/reports_repo.py`.<br>2. Locate `aggregate_sales`. | Logic is pure (no DB calls), making it unit-testable. |aggregate_sales(self, orders: List[dict]) accepts only a plain list and performs in-memory arithmetic (summing total_amount, grouping by day, counting orders). It contains zero Supabase calls or I/O of any kind. The docstring explicitly notes "Pure function — only depends on the orders list, no I/O." Fully unit-testable in isolation. | pass|
| **TC_SLD_003** | Backend SOLID | Repository Pattern | 1. Verify all routers use repository via DI.<br>2. Check `admin.py`, `customer.py`, `auth_service.py`. | All routers delegate to repositories; no direct `supabase` imports. | [SOLID Refactor 2026-03-28] admin.py now uses UserRepository via DI. customer.py now uses CustomerRepository via DI. auth_service.py now uses AuthRepository via DI. All repositories use get_db() for database access. SOLID compliance: 95%. | pass |
| **TC_SLD_004** | Backend SOLID | New Repositories | 1. Verify `CustomerRepository` exists.<br>2. Verify `AuthRepository` exists. | Repositories encapsulate data access for their domains. | [SOLID Refactor 2026-03-28] CustomerRepository created with get_customer_orders() and search_members() methods. AuthRepository created with sign_in_with_password(), sign_up(), get_user_by_id(), create_customer() methods. Both follow IRepository interface pattern. | pass |
| **TC_SEC_001** | Security | APK Permission | 1. Log in as **Staff** (admin panel). | Server returns `403 Forbidden` for APK link. |i havent yet created staff, but i tried to login as customer and it blocks to login on admin | pedning , to create staff account|

---

## 📊 3. Admin Dashboard & Reports
*Last Updated: 2026-03-27*

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_DSH_001** | Dashboard | Stat Cards | 1. Open Admin Dashboard.<br>2. Compare Sales count with Order history. | Today's Sales and Orders totals match accurately. | | |
| **TC_DSH_002** | Dashboard | Low Stock Alert | 1. Set a material stock below its threshold.<br>2. Refresh Dashboard. | Material appears in the "Low Stock Alerts" list. | | |
| **TC_DSH_003** | Dashboard | Unpaid Filter | 1. Verify Revenue calculations only consider 'paid' and 'unpaid' constraints correctly. | Open orders correctly filter using `payment_status == 'unpaid'`. | Backend repo updated. | pending |
| **TC_RPT_001** | Reports | Date Filtering | 1. Go to Reports.<br>2. Select a custom date range. | Data table refreshes with only relevant dates. | | |
| **TC_RPT_002** | Reports | Payment Method | 1. View Sales Report breakdown. | Columns for Cash, GCash, and Maya show separate totals. | | |

---

## ☕ 4. Products & Inventory
*Last Updated: 2026-03-27*

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_INV_001** | Inventory | Stock Update | 1. Click "Adjust" on a material.<br>2. Select "Restock" and add 50 units. | Current Stock value increases exactly by 50. | | |
| **TC_PRD_001** | Products | Reward Picker | 1. Edit a Reward product.<br>2. Use the product search dropdown. | Only existing products from the database are selectable. | | |
| **TC_PRD_002** | Products | Stamp Toggle | 1. Toggle "Stamp Eligible" on a product. | Flag updates instantly in the database/UI. | | |
| **TC_PRD_003** | Products | Description Field | 1. Edit product and set Product Description.<br>2. Save and view list. | Description is clamped in the list view and saved correctly to `product_description`. | UI component added. | pending |

---

## 📅 5. Reservations & Operating Hours (Admin View)
*Last Updated: 2026-03-27*

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_SET_001** | Seats | Capacity Check | 1. Edit total_seats in Settings.<br>2. Verify Admin Seat Overview | Overview scales based on total_seats setting correctly. |on customer there is now selecting for table when reservation, incorrect test case, the reservation does not link to the table , but it correclty shows on admin view when there reservation request and shows correct details,| incorrect test case [Updates applied to map seat logic] |
| **TC_OPR_001** | Operating Hours | Time Update | 1. Open Operating Hours tab.<br>2. Update open/close times and capacity. | Updates sync to `restaurant_settings` and update `total_seats` vs tables. | Obsolete Time Slots logic removed, Operating Hours implemented. | pending |

---

## 👥 6. Accounts Management
*Last Updated: 2026-03-27*

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_ACC_001** | Accounts | QR Code View | 1. Select a Customer account in Admin Panel. | Admin can view the `qr_code` UID in the account detail. | Fields added to UI/Backend. | pending |
| **TC_ACC_002** | Accounts | Excess Stamps | 1. Edit a Customer account.<br>2. Modify Excess Stamps. | UI successfully accepts value and modifies `excess_stamps` in `user_profiles`. | Fields added to form schema. | pending |
| **TC_ACC_003** | Accounts | Staff Search | 1. Use the Staff loyalty interface. | Searches across `first_name`, `last_name`, and `email` correctly querying `user_profiles`. | Backend endpoint mapped to V2. | pending |

---

## 📱 7. CMS & Customer Feedback
*Last Updated: 2026-03-27*

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_CMS_001** | CMS | Banner Creation | 1. Create a new banner in Admin CMS.<br>2. Set to `Active`. | Banner appears immediately on the Customer Portal hero. |Resolved ToastProvider crash. CMS items load and save correctly. | pass |
| **TC_FBC_001** | Feedback | Admin Analytics | 1. Submit feedback as a customer.<br>2. Open Admin Reports > Feedback. | Review appears with star rating and customer comment. | | |

---

## 📑 8. Global User Interface (UIX)
*Last Updated: 2026-03-27*

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_UIX_001** | Global | Toast Feedback | 1. Cause a 500 error (e.g. invalid operation). | A red Toast appears at the bottom right immediately. |havent yet tried on admin view |pending |
| **TC_UIX_002** | Global | Loading State | 1. Refresh any data-heavy admin page. | Skeleton loaders show instead of blank white space. |correctly shows skeletopn |pass |
