# Catsy Coffee — Complete System Test Case Suite

This document provides a structured set of test cases to verify the functionality, security, and architectural integrity of the Catsy Coffee ecosystem (Admin Panel, Customer Portal, and shared Backend).

---

## 🔐 0. Authentication & Security (Cross-Platform)

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_ATH_001** | Auth | Admin Web Login | 1. Navigate to `/login`.<br>2. Enter Admin credentials. | Redirects to `/admin/dashboard`. | | |
| **TC_ATH_002** | Auth | Customer Web Login | 1. Navigate to `/login`.<br>2. Enter Customer credentials. | Redirects to `/profile` or Home. | | |
| **TC_ATH_003** | Auth | Cross-Portal Denial | 1. Use **Staff** credentials on Web Login.<br>2. Attempt access to `/admin`. | System blocks access (403 or redirect to login). | | |
| **TC_ATH_004** | Auth | Logout Flow | 1. Click Profile icon > Logout. | Auth token cleared; redirected to Home. | | |

---

## 🛒 1. Customer Web Portal

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_CST_001** | Reservation | Guest Booking | 1. Go to Reservations.<br>2. Fill details as Guest.<br>3. Submit. | Receives "Reservation Pending" notification. | | |
| **TC_CST_002** | Reservation | Member Booking | 1. Login as Member.<br>2. Book a table. | Profile pre-fills; booking appears in history. | | |
| **TC_CST_003** | Reservation | Cancellation | 1. Go to "My Reservations".<br>2. Click "Cancel". | Status changes to "Cancelled"; seat freed. | | |
| **TC_CST_004** | UI Core | Nav Menu | 1. View on Mobile screen.<br>2. Click Hamburger menu. | Side menu slides in smoothly (GSAP animation). | | |
| **TC_UIX_003** | UI Core | Button States | 1. Click "Submit" on a slow network. | Button shows "Loading..." spinner + disables. | | |

---

## 🏗️ 2. Core Architecture (SOLID & Backend)

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_SLD_001** | Backend SOLID | Dependency Injection | 1. Open `app/routers/cms.py`.<br>2. Check for `Depends(get_repo)`. | Router delegates all DB work to `CmsRepository`. | | |
| **TC_SLD_002** | Backend SOLID | Pure Aggregation | 1. Inspect `app/repositories/reports_repo.py`.<br>2. Locate `aggregate_sales`. | Logic is pure (no DB calls), making it unit-testable. | | |
| **TC_SEC_001** | Security | APK Permission | 1. Log in as **Staff** (admin panel). | Server returns `403 Forbidden` for APK link. | | |

---

## 📊 3. Admin Dashboard & Reports

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_DSH_001** | Dashboard | Stat Cards | 1. Open Admin Dashboard.<br>2. Compare Sales count with Order history. | Today's Sales and Orders totals match accurately. | | |
| **TC_DSH_002** | Dashboard | Low Stock Alert | 1. Set a material stock below its threshold.<br>2. Refresh Dashboard. | Material appears in the "Low Stock Alerts" list. | | |
| **TC_RPT_001** | Reports | Date Filtering | 1. Go to Reports.<br>2. Select a custom date range. | Data table refreshes with only relevant dates. | | |
| **TC_RPT_002** | Reports | Payment Method | 1. View Sales Report breakdown. | Columns for Cash, GCash, and Maya show separate totals. | | |

---

## ☕ 4. Products & Inventory

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_INV_001** | Inventory | Stock Update | 1. Click "Adjust" on a material.<br>2. Select "Restock" and add 50 units. | Current Stock value increases exactly by 50. | | |
| **TC_PRD_001** | Products | Reward Picker | 1. Edit a Reward product.<br>2. Use the product search dropdown. | Only existing products from the database are selectable. | | |
| **TC_PRD_002** | Products | Stamp Toggle | 1. Toggle "Stamp Eligible" on a product. | Flag updates instantly in the database/UI. | | |

---

## 📅 5. Reservations & Seats (Admin View)

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_SET_001** | Seats | Live Seat Map | 1. Create a reservation for "Table 1".<br>2. Refresh Admin Seat Map. | "Table 1" turns Blue (Reserved) with customer name. | | |
| **TC_SLT_001** | Time Slots | Initialization | 1. First time opening the Slots page. | Page is pre-populated with default 5PM-12AM slots. | | |
| **TC_SLT_002** | Time Slots | Conflict Check | 1. Attempt to delete a slot with pending bookings. | System shows a confirmation dialog with warning. | | |

---

## 🖼️ 6. CMS & Community

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_CMS_001** | CMS | Banner Creation | 1. Create a new banner in Admin CMS.<br>2. Set to `Active`. | Banner appears immediately on the Customer Portal hero. | | |
| **TC_FBC_001** | Feedback | Admin Analytics | 1. Submit feedback as a customer.<br>2. Open Admin Reports > Feedback. | Review appears with star rating and customer comment. | | |

---

## 📑 7. Global User Interface (UIX)

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_UIX_001** | Global | Toast Feedback | 1. Cause a 500 error (e.g. invalid operation). | A red Toast appears at the bottom right immediately. | | |
| **TC_UIX_002** | Global | Loading State | 1. Refresh any data-heavy admin page. | Skeleton loaders show instead of blank white space. | | |
