# Catsy Coffee Portal — Development Log

## Session Date: 2026-03-26

This log summarizes the technical debt resolution, profile persistence fixes, and UI/UX refinements implemented to finalize the Catsy Coffee Customer Web Portal.

---

### 1. 🚀 Backend Architecture & Stability (Deadlock Resolution)
**Objective:** Eliminate the UI freezing issue where the app would hang indefinitely during login/signup.

- **Files Edited:**
  - `catsy-backend/app/services/auth_service.py`
  - `catsy-backend/app/routers/auth.py`
- **Changes:**
  - Converted `AuthService` methods (login/signup) and their corresponding router handlers from `async def` to synchronous `def`.
  - **Reasoning:** Supabase network calls are blocking. By using `def`, FastAPI automatically offloads these tasks to a separate thread pool, preventing the main event loop from deadlocking while waiting for Supabase responses.

### 2. 👤 Profile Persistence & Data Integrity
**Objective:** Ensure user metadata (username, name, phone) persists correctly and displays on the Profile Tab.

- **Files Edited:**
  - `catsy-backend/app/services/auth_service.py` (Fixed signup insertion & added lazy-create)
  - `catsy-web/src/hooks/useAuth.js` (Fixed username mapping)
  - `catsy-web/src/pages/ProfilePage.jsx` (Added robust data fallbacks)
- **Changes:**
  - **Lazy Creation:** Added logic to `customer_login` to automatically create a `customers` database row if it is missing but the Auth user exists.
  - **Metadata Flattening:** The backend now flattens `user_metadata` into the top-level response object, ensuring the frontend always sees fields like `first_name` even if the DB sync is delayed.
  - **Field Mapping:** Fixed a bug in `useAuth.js` where the `username` field was being dropped during the signup payload transmission.

### 3. ✨ UI/UX Aesthetic Refinement
**Objective:** Unify the design language across all portals and improve visual accessibility.

- **Files Edited:**
  - `catsy-web/src/pages/LoginPage.jsx` (Full theme overhaul)
  - `catsy-web/src/pages/ProfilePage.jsx` (Button contrast update)
  - `catsy-web/src/components/Dashboard/IdentityHub.jsx` (Data binding refinements)
- **Changes:**
  - **Premium Login Theme:** Transformed the login page from a plain white background to a sophisticated "Dark Background + White Card" layout to match the Reservation portal.
  - **High-Contrast Buttons:** Updated "Edit" and "Save" buttons in the Profile tab to use white-on-dark styles, resolving feedback about "black buttons" being hard to see.
  - **Greeting Fallbacks:** Fixed "Welcome back, undefined" notifications by adding robust fallbacks to use the username or a generic "Friend" if the first name is missing.

---

### ✅ Summary of Fixes:
- [x] Resolved event-loop deadlock (UI no longer hangs).
- [x] Fixed profile data not populating after registration.
- [x] Unified "Dark/White Mix" aesthetic across Login and Reservations.
- [x] Corrected case-sensitivity mapping between Backend (snake_case) and Frontend (camelCase).
- [x] Verified unique QR code persistence on Digital ID cards.
