# Catsy Coffee — Complete System Test Case Suite

This document provides a structured set of test cases to verify the functionality, security, and architectural integrity of the Catsy Coffee ecosystem (Admin Panel, Customer Portal, and shared Backend).

---

## 🔐 0. Authentication & Security (Cross-Platform)

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_ATH_001** | Auth | Admin Web Login | 1. Navigate to `/login`.<br>2. Enter Admin credentials. | Redirects to `/admin/dashboard`. |succusfly login goes to dashboard page | pass |
| **TC_ATH_002** | Auth | Customer Web Login | 1. Navigate to `/login`.<br>2. Enter Customer credentials. | Redirects to `/profile` or Home. |succufuly login, goes to profile page |pass |
| **TC_ATH_003** | Auth | Cross-Portal Denial | 1. Use **Staff** credentials on Web Login.<br>2. Attempt access to `/admin`. | System blocks access (403 or redirect to login). |i tried to login usig customer account, it does not goes or blocks to redirect to admin dashboard and clears the login form, but no shows notifaiction or message that no access to admin page, havent tried yet on staff , not created yet account for staff , check if cusomter and staff have same behaviour  |pending |
| **TC_ATH_004** | Auth | Logout Flow | 1. Click Profile icon > Logout. | Auth token cleared; redirected to Home. | on cusomter web, it works, on admin web, there is no logout button for admin, no profile icon on admin | pass on customer web, pending on admin web |

---

## 🛒 1. Customer Web Portal

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_CST_001** | Reservation | Guest Booking | 1. Go to Reservations.<br>2. Fill details as Guest.<br>3. Submit. | Receives "Reservation Pending" notification. |succusfuly filled form in the login account, shows notification ,waiting confirmation, on guest same behaviour successfuly shows waiting confiramtion, one thing to add no error labels on fields if empty or incorrect input | pass, need label erro each fields |
| **TC_CST_002** | Reservation | Member Booking | 1. Login as Member.<br>2. Book a table. | Profile pre-fills; booking appears in history. |succesfuly prefills all fields |pass |
| **TC_CST_003** | Reservation | Cancellation | 1. Go to "My Reservations".<br>2. Click "Cancel". | Status changes to "Cancelled"; seat freed. |i go to reservation as login, no shows cancel button only waiting confimation details |can't test it no cancel btn |
| **TC_CST_004** | UI Core | Nav Menu | 1. View on Mobile screen.<br>2. Click Hamburger menu. | Side menu slides in smoothly (GSAP animation). |succuelfy can view menu on mobile device navitae to pages, but no smooth slides of menu| pass, no smooth slides of menu  |
| **TC_UIX_003** | UI Core | Button States | 1. Click "Submit" on a slow network. | Button shows "Loading..." spinner + disables. |successfuly shows loading on sumbit reservation, on login it change the state of btn to inactive processing... (add in here when loading make the dots also like its incrementing and reset max 3 like if loading . .. ... you get me?), in loyalty card successfuly shows skeleton |  pass|

---

## 🏗️ 2. Core Architecture (SOLID & Backend)

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_SLD_001** | Backend SOLID | Dependency Injection | 1. Open `app/routers/cms.py`.<br>2. Check for `Depends(get_repo)`. | Router delegates all DB work to `CmsRepository`. |All four route handlers (get_cms_items, create_cms_item, update_cms_item, delete_cms_item, get_public_cms) declare repo: CmsRepository = Depends(get_repo). No Supabase calls exist in the router — all DB work is delegated to CmsRepository. The get_repo() factory is also swappable in tests, confirming DIP compliance. | pass |
| **TC_SLD_002** | Backend SOLID | Pure Aggregation | 1. Inspect `app/repositories/reports_repo.py`.<br>2. Locate `aggregate_sales`. | Logic is pure (no DB calls), making it unit-testable. |ggregate_sales(self, orders: List[dict]) accepts only a plain list and performs in-memory arithmetic (summing total_amount, grouping by day, counting orders). It contains zero Supabase calls or I/O of any kind. The docstring explicitly notes "Pure function — only depends on the orders list, no I/O." Fully unit-testable in isolation. | pass|
| **TC_SEC_001** | Security | APK Permission | 1. Log in as **Staff** (admin panel). | Server returns `403 Forbidden` for APK link. |i havent yet created staff, but i tried to login as customer and it blocks to login on admin | pedning , to create staff account|

---

## 📊 3. Admin Dashboard & Reports
## THIS DONT HAVE ANY DATA YET CANT TEST THIS, FOR TEST CAN U SEED THE DATABASE?
| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_DSH_001** | Dashboard | Stat Cards | 1. Open Admin Dashboard.<br>2. Compare Sales count with Order history. | Today's Sales and Orders totals match accurately. | | |
| **TC_DSH_002** | Dashboard | Low Stock Alert | 1. Set a material stock below its threshold.<br>2. Refresh Dashboard. | Material appears in the "Low Stock Alerts" list. | | |
| **TC_RPT_001** | Reports | Date Filtering | 1. Go to Reports.<br>2. Select a custom date range. | Data table refreshes with only relevant dates. | | |
| **TC_RPT_002** | Reports | Payment Method | 1. View Sales Report breakdown. | Columns for Cash, GCash, and Maya show separate totals. | | |

---

## ☕ 4. Products & Inventory
## INVETORY, CLAIMABLE REWARDS, PRODUCTS, ACCOUNTS DOES NOT RETURN ANY DATA OR DISPALY ANYTHING, 
| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_INV_001** | Inventory | Stock Update | 1. Click "Adjust" on a material.<br>2. Select "Restock" and add 50 units. | Current Stock value increases exactly by 50. | | |
| **TC_PRD_001** | Products | Reward Picker | 1. Edit a Reward product.<br>2. Use the product search dropdown. | Only existing products from the database are selectable. | | |
| **TC_PRD_002** | Products | Stamp Toggle | 1. Toggle "Stamp Eligible" on a product. | Flag updates instantly in the database/UI. | | |

---

## 📅 5. Reservations & Seats (Admin View)
## NO TABLES SEATS CONFIGURE YET, CANT TEST THIS
## ON RESERVATION 

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_SET_001** | Seats | Live Seat Map | 1. Create a reservation for "Table 1".<br>2. Refresh Admin Seat Map. | "Table 1" turns Blue (Reserved) with customer name. |on customer there is now selecting for table when reservation, incorrect test case, the reservation does not link to the table , but it correclty shows on admin view when there reservation request and shows correct details,| incorrect test case  |
| **TC_SLT_001** | Time Slots | Initialization | 1. First time opening the Slots page. | Page is pre-populated with default 5PM-12AM slots. |if u mean on reservation tab , the store operational sync, the opening and closing when clicking the collapse settting shows opening to 8Am closing 10PM and selected confirm, it will populate the opening and clsing, by start page does not shows anytime, so it fails on first time opening page if u mean on reservation on admin  |fail|
| **TC_SLT_002** | Time Slots | Conflict Check | 1. Attempt to delete a slot with pending bookings. | System shows a confirmation dialog with warning. |actualy the time slots tab have erros shows | logger.js:8 App Rendered.
logger.js:8 App Rendered.
logger.js:8 Session restored
logger.js:8 Session restored
logger.js:8 App Rendered.
logger.js:8 App Rendered.
logger.js:8 App Rendered.
logger.js:8 App Rendered.
AdminPage.jsx:310 Error: useToast must be used inside ToastProvider
    at useToast (ToastContext.jsx:43:19)
    at TimeSlotsPage (TimeSlotsPage.jsx:16:17)
    at Object.react_stack_bottom_frame (react-dom_client.js?v=4231da51:18509:20)
    at renderWithHooks (react-dom_client.js?v=4231da51:5654:24)
    at updateFunctionComponent (react-dom_client.js?v=4231da51:7475:21)
    at beginWork (react-dom_client.js?v=4231da51:8525:20)
    at runWithFiberInDEV (react-dom_client.js?v=4231da51:997:72)
    at performUnitOfWork (react-dom_client.js?v=4231da51:12561:98)
    at workLoopSync (react-dom_client.js?v=4231da51:12424:43)
    at renderRootSync (react-dom_client.js?v=4231da51:12408:13)

The above error occurred in the <TimeSlotsPage> component.

React will try to recreate this component tree from scratch using the error boundary you provided, ErrorBoundary.

defaultOnCaughtError @ react-dom_client.js?v=4231da51:7001
logCaughtError @ react-dom_client.js?v=4231da51:7033
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
inst.componentDidCatch.update.callback @ react-dom_client.js?v=4231da51:7078
callCallback @ react-dom_client.js?v=4231da51:5491
commitCallbacks @ react-dom_client.js?v=4231da51:5503
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
commitClassCallbacks @ react-dom_client.js?v=4231da51:9490
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9958
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9963
flushLayoutEffects @ react-dom_client.js?v=4231da51:12924
commitRoot @ react-dom_client.js?v=4231da51:12803
commitRootWhenReady @ react-dom_client.js?v=4231da51:12016
performWorkOnRoot @ react-dom_client.js?v=4231da51:11950
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<TimeSlotsPage>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
AdminPage @ AdminPage.jsx:310
react_stack_bottom_frame @ react-dom_client.js?v=4231da51:18509
renderWithHooksAgain @ react-dom_client.js?v=4231da51:5729
renderWithHooks @ react-dom_client.js?v=4231da51:5665
updateFunctionComponent @ react-dom_client.js?v=4231da51:7475
beginWork @ react-dom_client.js?v=4231da51:8525
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
performUnitOfWork @ react-dom_client.js?v=4231da51:12561
workLoopSync @ react-dom_client.js?v=4231da51:12424
renderRootSync @ react-dom_client.js?v=4231da51:12408
performWorkOnRoot @ react-dom_client.js?v=4231da51:11827
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<AdminPage>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
AppContent @ App.jsx:80
react_stack_bottom_frame @ react-dom_client.js?v=4231da51:18509
renderWithHooksAgain @ react-dom_client.js?v=4231da51:5729
renderWithHooks @ react-dom_client.js?v=4231da51:5665
updateFunctionComponent @ react-dom_client.js?v=4231da51:7475
beginWork @ react-dom_client.js?v=4231da51:8525
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
performUnitOfWork @ react-dom_client.js?v=4231da51:12561
workLoopSync @ react-dom_client.js?v=4231da51:12424
renderRootSync @ react-dom_client.js?v=4231da51:12408
performWorkOnRoot @ react-dom_client.js?v=4231da51:11827
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<AppContent>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
App @ App.jsx:127
react_stack_bottom_frame @ react-dom_client.js?v=4231da51:18509
renderWithHooksAgain @ react-dom_client.js?v=4231da51:5729
renderWithHooks @ react-dom_client.js?v=4231da51:5665
updateFunctionComponent @ react-dom_client.js?v=4231da51:7475
beginWork @ react-dom_client.js?v=4231da51:8525
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
performUnitOfWork @ react-dom_client.js?v=4231da51:12561
workLoopSync @ react-dom_client.js?v=4231da51:12424
renderRootSync @ react-dom_client.js?v=4231da51:12408
performWorkOnRoot @ react-dom_client.js?v=4231da51:11766
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<App>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
(anonymous) @ main.jsx:27
logger.js:9 ErrorBoundary caught an error: Error: useToast must be used inside ToastProvider
    at useToast (ToastContext.jsx:43:19)
    at TimeSlotsPage (TimeSlotsPage.jsx:16:17)
    at Object.react_stack_bottom_frame (react-dom_client.js?v=4231da51:18509:20)
    at renderWithHooks (react-dom_client.js?v=4231da51:5654:24)
    at updateFunctionComponent (react-dom_client.js?v=4231da51:7475:21)
    at beginWork (react-dom_client.js?v=4231da51:8525:20)
    at runWithFiberInDEV (react-dom_client.js?v=4231da51:997:72)
    at performUnitOfWork (react-dom_client.js?v=4231da51:12561:98)
    at workLoopSync (react-dom_client.js?v=4231da51:12424:43)
    at renderRootSync (react-dom_client.js?v=4231da51:12408:13) {componentStack: '\n    at TimeSlotsPage (http://localhost:5173/src/p…s/.vite/deps/chunk-ZWYRVHOL.js?v=4231da51:3130:3)'}
error @ logger.js:9
componentDidCatch @ ErrorBoundary.jsx:16
react_stack_bottom_frame @ react-dom_client.js?v=4231da51:18547
inst.componentDidCatch.update.callback @ react-dom_client.js?v=4231da51:7086
callCallback @ react-dom_client.js?v=4231da51:5491
commitCallbacks @ react-dom_client.js?v=4231da51:5503
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
commitClassCallbacks @ react-dom_client.js?v=4231da51:9490
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9958
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9963
flushLayoutEffects @ react-dom_client.js?v=4231da51:12924
commitRoot @ react-dom_client.js?v=4231da51:12803
commitRootWhenReady @ react-dom_client.js?v=4231da51:12016
performWorkOnRoot @ react-dom_client.js?v=4231da51:11950
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<ErrorBoundary>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
App @ App.jsx:124
react_stack_bottom_frame @ react-dom_client.js?v=4231da51:18509
renderWithHooksAgain @ react-dom_client.js?v=4231da51:5729
renderWithHooks @ react-dom_client.js?v=4231da51:5665
updateFunctionComponent @ react-dom_client.js?v=4231da51:7475
beginWork @ react-dom_client.js?v=4231da51:8525
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
performUnitOfWork @ react-dom_client.js?v=4231da51:12561
workLoopSync @ react-dom_client.js?v=4231da51:12424
renderRootSync @ react-dom_client.js?v=4231da51:12408
performWorkOnRoot @ react-dom_client.js?v=4231da51:11766
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<App>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
(anonymous) @ main.jsx:27
 Error: useToast must be used inside ToastProvider|

---

## 🖼️ 6. CMS & Community
## TIHS PAGE HAVE ERROR:

The deferred DOM Node could not be resolved to a valid node.
logger.js:8 App Rendered.
logger.js:8 App Rendered.
logger.js:8 Session restored
logger.js:8 Session restored
logger.js:8 App Rendered.
logger.js:8 App Rendered.
logger.js:8 App Rendered.
logger.js:8 App Rendered.
AdminPage.jsx:312 Error: useToast must be used inside ToastProvider
    at useToast (ToastContext.jsx:43:19)
    at CmsPage (CmsPage.jsx:19:17)
    at Object.react_stack_bottom_frame (react-dom_client.js?v=4231da51:18509:20)
    at renderWithHooks (react-dom_client.js?v=4231da51:5654:24)
    at updateFunctionComponent (react-dom_client.js?v=4231da51:7475:21)
    at beginWork (react-dom_client.js?v=4231da51:8525:20)
    at runWithFiberInDEV (react-dom_client.js?v=4231da51:997:72)
    at performUnitOfWork (react-dom_client.js?v=4231da51:12561:98)
    at workLoopSync (react-dom_client.js?v=4231da51:12424:43)
    at renderRootSync (react-dom_client.js?v=4231da51:12408:13)

The above error occurred in the <CmsPage> component.

React will try to recreate this component tree from scratch using the error boundary you provided, ErrorBoundary.

defaultOnCaughtError @ react-dom_client.js?v=4231da51:7001
logCaughtError @ react-dom_client.js?v=4231da51:7033
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
inst.componentDidCatch.update.callback @ react-dom_client.js?v=4231da51:7078
callCallback @ react-dom_client.js?v=4231da51:5491
commitCallbacks @ react-dom_client.js?v=4231da51:5503
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
commitClassCallbacks @ react-dom_client.js?v=4231da51:9490
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9958
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9963
flushLayoutEffects @ react-dom_client.js?v=4231da51:12924
commitRoot @ react-dom_client.js?v=4231da51:12803
commitRootWhenReady @ react-dom_client.js?v=4231da51:12016
performWorkOnRoot @ react-dom_client.js?v=4231da51:11950
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<CmsPage>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
AdminPage @ AdminPage.jsx:312
react_stack_bottom_frame @ react-dom_client.js?v=4231da51:18509
renderWithHooksAgain @ react-dom_client.js?v=4231da51:5729
renderWithHooks @ react-dom_client.js?v=4231da51:5665
updateFunctionComponent @ react-dom_client.js?v=4231da51:7475
beginWork @ react-dom_client.js?v=4231da51:8525
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
performUnitOfWork @ react-dom_client.js?v=4231da51:12561
workLoopSync @ react-dom_client.js?v=4231da51:12424
renderRootSync @ react-dom_client.js?v=4231da51:12408
performWorkOnRoot @ react-dom_client.js?v=4231da51:11827
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<AdminPage>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
AppContent @ App.jsx:80
react_stack_bottom_frame @ react-dom_client.js?v=4231da51:18509
renderWithHooksAgain @ react-dom_client.js?v=4231da51:5729
renderWithHooks @ react-dom_client.js?v=4231da51:5665
updateFunctionComponent @ react-dom_client.js?v=4231da51:7475
beginWork @ react-dom_client.js?v=4231da51:8525
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
performUnitOfWork @ react-dom_client.js?v=4231da51:12561
workLoopSync @ react-dom_client.js?v=4231da51:12424
renderRootSync @ react-dom_client.js?v=4231da51:12408
performWorkOnRoot @ react-dom_client.js?v=4231da51:11827
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<AppContent>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
App @ App.jsx:127
react_stack_bottom_frame @ react-dom_client.js?v=4231da51:18509
renderWithHooksAgain @ react-dom_client.js?v=4231da51:5729
renderWithHooks @ react-dom_client.js?v=4231da51:5665
updateFunctionComponent @ react-dom_client.js?v=4231da51:7475
beginWork @ react-dom_client.js?v=4231da51:8525
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
performUnitOfWork @ react-dom_client.js?v=4231da51:12561
workLoopSync @ react-dom_client.js?v=4231da51:12424
renderRootSync @ react-dom_client.js?v=4231da51:12408
performWorkOnRoot @ react-dom_client.js?v=4231da51:11766
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<App>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
(anonymous) @ main.jsx:27
logger.js:9 ErrorBoundary caught an error: Error: useToast must be used inside ToastProvider
    at useToast (ToastContext.jsx:43:19)
    at CmsPage (CmsPage.jsx:19:17)
    at Object.react_stack_bottom_frame (react-dom_client.js?v=4231da51:18509:20)
    at renderWithHooks (react-dom_client.js?v=4231da51:5654:24)
    at updateFunctionComponent (react-dom_client.js?v=4231da51:7475:21)
    at beginWork (react-dom_client.js?v=4231da51:8525:20)
    at runWithFiberInDEV (react-dom_client.js?v=4231da51:997:72)
    at performUnitOfWork (react-dom_client.js?v=4231da51:12561:98)
    at workLoopSync (react-dom_client.js?v=4231da51:12424:43)
    at renderRootSync (react-dom_client.js?v=4231da51:12408:13) {componentStack: '\n    at CmsPage (http://localhost:5173/src/pages/a…s/.vite/deps/chunk-ZWYRVHOL.js?v=4231da51:3130:3)'}
error @ logger.js:9
componentDidCatch @ ErrorBoundary.jsx:16
react_stack_bottom_frame @ react-dom_client.js?v=4231da51:18547
inst.componentDidCatch.update.callback @ react-dom_client.js?v=4231da51:7086
callCallback @ react-dom_client.js?v=4231da51:5491
commitCallbacks @ react-dom_client.js?v=4231da51:5503
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
commitClassCallbacks @ react-dom_client.js?v=4231da51:9490
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9958
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9903
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:10074
recursivelyTraverseLayoutEffects @ react-dom_client.js?v=4231da51:10792
commitLayoutEffectOnFiber @ react-dom_client.js?v=4231da51:9963
flushLayoutEffects @ react-dom_client.js?v=4231da51:12924
commitRoot @ react-dom_client.js?v=4231da51:12803
commitRootWhenReady @ react-dom_client.js?v=4231da51:12016
performWorkOnRoot @ react-dom_client.js?v=4231da51:11950
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<ErrorBoundary>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
App @ App.jsx:124
react_stack_bottom_frame @ react-dom_client.js?v=4231da51:18509
renderWithHooksAgain @ react-dom_client.js?v=4231da51:5729
renderWithHooks @ react-dom_client.js?v=4231da51:5665
updateFunctionComponent @ react-dom_client.js?v=4231da51:7475
beginWork @ react-dom_client.js?v=4231da51:8525
runWithFiberInDEV @ react-dom_client.js?v=4231da51:997
performUnitOfWork @ react-dom_client.js?v=4231da51:12561
workLoopSync @ react-dom_client.js?v=4231da51:12424
renderRootSync @ react-dom_client.js?v=4231da51:12408
performWorkOnRoot @ react-dom_client.js?v=4231da51:11766
performWorkOnRootViaSchedulerTask @ react-dom_client.js?v=4231da51:13505
performWorkUntilDeadline @ react-dom_client.js?v=4231da51:36
<App>
exports.jsxDEV @ react_jsx-dev-runtime.js?v=4231da51:247
(anonymous) @ main.jsx:27

Error: useToast must be used inside ToastProvider
| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_CMS_001** | CMS | Banner Creation | 1. Create a new banner in Admin CMS.<br>2. Set to `Active`. | Banner appears immediately on the Customer Portal hero. | | |
| **TC_FBC_001** | Feedback | Admin Analytics | 1. Submit feedback as a customer.<br>2. Open Admin Reports > Feedback. | Review appears with star rating and customer comment. | | |

---

## 📑 7. Global User Interface (UIX)

| Test ID | Module | Scenario | Test Steps | Expected Result | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC_UIX_001** | Global | Toast Feedback | 1. Cause a 500 error (e.g. invalid operation). | A red Toast appears at the bottom right immediately. |havent yet tried on admin view |pending |

| **TC_UIX_002** | Global | Loading State | 1. Refresh any data-heavy admin page. | Skeleton loaders show instead of blank white space. |correctly shows skeletopn |pass |
