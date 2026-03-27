---
description: AI orchestration workflow — read the codebase, align with MD specs, detect phase status, and determine what to build next
---

# CUTshier / Catsy Coffee — AI Orchestration Workflow

> **Purpose:** This workflow tells the AI exactly what to read first, how to determine the current project state, what phase is active, and what the next task should be. Run this at the start of every AI session before writing any code.

---

## 🚫 AI HARD RULES — Read Before Every Session

These rules are **absolute**. No exceptions. No overrides.

| Rule | Detail |
|---|---|
| **NEVER mark a test `pass` or `fail`** | `test_cases.md` Status column is **human-only**. If you applied a fix, you may write `[Fix Applied] <what changed>` in the Actual Outcome column. The Status **must stay `pending`** until the human manually tests and explicitly updates it. |
| **NEVER edit spec files** | `catsy.md`, `catsy_development_phases.md`, `phase3.md` are read-only references. |
| **NEVER modify `FROZEN.md`** | Unless the user explicitly asks for an audit. |
| **ALWAYS log your session** | Add an entry to `DEVELOPMENT_LOG.md` after any coding session. |

---


Before anything else, always sync with the remote repository.

```bash
git checkout main
git pull
```

If you are on a feature branch, confirm you have pulled the latest base first.

---

---

## ⚡ FAST PATH — Read These First (Low Token, High Signal)

> **Before loading any large spec docs, read these two files first.**
> They contain the current project state and what you're NOT allowed to touch.

| File | Read | Why |
|---|---|---|
| `currentPhases.md` | **FIRST — always** | Tells you what's done, what's active, what to do next. Saves you reading 800+ lines of spec. |
| `FROZEN.md` | **SECOND — always** | Lists every SOLID-verified file. Do not modify any of these without adding a `DEVELOPMENT_LOG.md` entry first. |

**If `currentPhases.md` answers your question → skip Steps 1–4 entirely and go straight to Step 5.**

---

## STEP 1 — Load Full Docs Only If Needed

> **Only load these if you can't determine the answer from `currentPhases.md`.**

| Load When | File | What it tells you |
|---|---|---|
| Resolving a spec dispute | `catsy.md` | Full SRS — all FRs |
| Checking phase deliverables | `catsy_development_phases.md` | Full 7-phase build plan |
| Understanding built features | `implemented_features.md` | What is production-ready |
| Debugging a recent issue | `DEVELOPMENT_LOG.md` | Session history |
| Phase 3 deep-dive | `phase3.md` | Code examples + admin panel guide |
| Running tests | `test_cases.md` | QA test scenarios |
| Git/PR rules | `MUSTREAD.md` | Branching and commit rules |

---

## STEP 2 — Audit the Codebase Structure

After reading the docs, scan the actual code to understand what exists.

### 2a. Backend

```bash
find /mnt/datadrive/Project/Catsy-Final/catsy-backend/app -type f -name "*.py" | sort
```

**Check for these critical modules:**

| Module | Expected path | If missing |
|---|---|---|
| Auth router | `app/routers/auth.py` | Phase 1 incomplete |
| Auth service | `app/services/auth_service.py` | Phase 1 incomplete |
| Order repository | `app/repositories/order_repo.py` | Phase 2 gaps |
| Loyalty repository | `app/repositories/loyalty_repo.py` | Phase 2 gaps |
| Reservation repository | `app/repositories/reservation_repo.py` | Phase 2 gaps |
| Reports repository | `app/repositories/reports_repo.py` | Phase 3 incomplete |
| Seats repository | `app/repositories/seats_repo.py` | Phase 3 incomplete |
| Settings repository | `app/repositories/settings_repo.py` | Phase 3 incomplete |
| CMS repository | `app/repositories/cms_repo.py` | Phase 3 incomplete |
| Materials repository | `app/repositories/materials_repo.py` | Phase 3 incomplete |
| Central schemas | `app/schemas.py` | SOLID audit failure |

### 2b. Frontend

```bash
find /mnt/datadrive/Project/Catsy-Final/catsy-web/src -type f -name "*.jsx" -o -name "*.js" | sort
```

**Check for these critical files:**

| File | Expected path | Phase |
|---|---|---|
| `AdminPage.jsx` | `src/pages/admin/AdminPage.jsx` | Phase 3 |
| `DashboardPage.jsx` | `src/pages/admin/DashboardPage.jsx` | Phase 3 |
| `ProductsPage.jsx` | `src/pages/admin/ProductsPage.jsx` | Phase 3 |
| `InventoryPage.jsx` | `src/pages/admin/InventoryPage.jsx` | Phase 3 |
| `ReportsPage.jsx` | `src/pages/admin/ReportsPage.jsx` | Phase 3 |
| `CmsPage.jsx` | `src/pages/admin/CmsPage.jsx` | Phase 3 |
| `TimeSlotsPage.jsx` | `src/pages/admin/TimeSlotsPage.jsx` | Phase 3 |
| `SeatOverviewPage.jsx` | `src/pages/admin/SeatOverviewPage.jsx` | Phase 3 |
| `ApkDownloadPage.jsx` | `src/pages/admin/ApkDownloadPage.jsx` | Phase 3 |
| `LoginPage.jsx` | `src/pages/LoginPage.jsx` | Phase 4 |
| `ReservationPage.jsx` | `src/pages/ReservationPage.jsx` | Phase 4 |
| `ProfilePage.jsx` | `src/pages/ProfilePage.jsx` | Phase 4 |
| `ToastContext.jsx` | `src/context/ToastContext.jsx` | Phase 5 |
| `apiClient.js` | `src/api/apiClient.js` | Phase 1 |
| `App.jsx` | `src/App.jsx` | Phase 1 |

### 2c. Mobile (if applicable)

```bash
find /mnt/datadrive/Project/Catsy-Final/catsy_mobile -type f \( -name "*.dart" -o -name "*.md" \) | sort
```

---

## STEP 3 — Determine the Current Phase

Cross-reference `catsy_development_phases.md` deliverables checklists against what the codebase contains.

### Phase Status Decision Table

Work through this table **top to bottom** and stop at the first failing phase:

| Phase | Gate Condition (all must be true) | Check How |
|---|---|---|
| **Phase 1 ✅** | Git repo initialized; DB migrations exist; JWT auth returns token on `/api/auth/login`; `.env.example` committed; route shells exist | Check `catsy-backend/` for migration files + `app/routers/auth.py`; check `catsy-web/src/App.jsx` for route definitions |
| **Phase 2 ✅** | All REST endpoints exist for auth, products, inventory, orders, stamps, reservations, seats, notifications, feedback | Check each router file in `app/routers/`; look for missing routes against section 2.1–2.10 of dev phases doc |
| **Phase 3 ✅** | All 11 admin panel sections built and wired to backend | Check all admin page files listed in Step 2b above exist and import correct API hooks |
| **Phase 4 ✅** | All customer portal pages exist; reservation flow works; QR code + loyalty UI complete | Check customer page files; look for `StampCard`, `QRDisplay`, reservation step components |
| **Phase 5 ✅** | Toast system global; all buttons have loading/disabled states; skeleton loaders present; offline indicator present | Check `ToastContext.jsx` is in `App.jsx` root; grep for `loading=` in major pages |
| **Phase 6** | Integration tests pass; security checklist items verified | Run test suite from `test_cases.md`; check role-based 403 rejections |
| **Phase 7** | Deployed to production; mobile dev handover docs in `/docs/` | Check `catsy_mobile/TECHNICAL_DEBT.md` for mobile dev status |

### Quick Phase Determination Commands

```bash
# Phase 2 — check all routers exist
ls /mnt/datadrive/Project/Catsy-Final/catsy-backend/app/routers/

# Phase 3 — check all admin pages
ls /mnt/datadrive/Project/Catsy-Final/catsy-web/src/pages/admin/

# Phase 4 — check customer pages
ls /mnt/datadrive/Project/Catsy-Final/catsy-web/src/pages/

# Phase 5 — check Toast is in App root
grep -n "ToastProvider" /mnt/datadrive/Project/Catsy-Final/catsy-web/src/App.jsx
```

---

## STEP 4 — Cross-Check: Spec vs Implementation

For each functional requirement in `catsy.md`, verify the corresponding code exists.

### Admin (FR A1–A11 + new additions)

| Requirement | FR ID | Where to verify |
|---|---|---|
| Admin login | FR A1 | `/admin/login` route + `auth.py` |
| Manage employees | FR A2 | `app/routers/employees.py` + `EmployeesPage.jsx` |
| Manage products + stamp eligibility | FR A3 | `productsApi.js` has stamp-eligible toggle; reward items use product picker (not free text) |
| Manage inventory | FR A4 | `InventoryPage.jsx` has adjust modal with reason dropdown |
| Product sales analysis | FR A5 | `ReportsPage.jsx` has best-selling / slow-moving tables |
| Inventory analysis | FR A6 | Reports page includes depletion rate per product |
| View feedback | FR A7 | Reports page has feedback viewer section |
| Notifications | FR A8 | Notification bell in admin header with badge count |
| Security/permissions | FR A9 | Admin routes return 403 for staff/customer tokens |
| CMS | FR A10 | `CmsPage.jsx` exists with banner/announcement/promo CRUD |
| APK download | FR A11 | `ApkDownloadPage.jsx` behind admin-only guard |
| Seat overview (read-only) | FR A-new | `SeatOverviewPage.jsx` read-only, no staff controls |
| Manage operating hours | FR A-new | `TimeSlotsPage.jsx` (repurposed for Operating Hours) with default 5PM–12AM on first run |

### Staff (FR S1–S8)

| Requirement | FR ID | Where to verify |
|---|---|---|
| View reservations + no-show notification | FR S1 | Mobile app scope — check `catsy_mobile/` |
| Approve/decline reservations | FR S2 | Mobile app scope |
| Record orders (dine-in/take-out, pay-now/pay-later) | FR S3 | Mobile app scope |
| Customer account handling | FR S4 | Mobile app scope |
| Payment processing (Cash/GCash/Maya + change_due) | FR S5 | `POST /api/staff/orders/:id/pay` returns `change_due`; check `schemas.py` for `OrderPayRequest` |
| Seat map toggle | FR S6 | Mobile app scope |
| Process refund + stamp deduction | FR S7 | `POST /api/staff/orders/:id/refund` in `app/routers/` |
| Stamp transaction (QR scan + member list) | FR S8 | `POST /api/staff/stamps/credit` + `GET /api/staff/members?search=` |

### Customer (FR C1–C8)

| Requirement | FR ID | Where to verify |
|---|---|---|
| Live seat vacancy (text only) | FR C1 | Customer portal shows count, NOT a seat map |
| Reserve a seat (guest + logged in, cancel option) | FR C2 | `ReservationPage.jsx` has cancel button for pending reservations |
| Create account | FR C3 | Register page + `auth_service.py` lazy-create |
| View loyalty stamps | FR C4 | Dashboard shows 3×3 grid |
| View + download QR code | FR C5 | QR download works as PNG |
| Earn stamps | FR C6 | Stamp crediting via staff, not auto |
| Claim reward (reward list modal + unique QR code) | FR C7 | `POST /api/customer/rewards/generate` exists; reward code is single-use |
| Purchase history + feedback | FR C8 | Order history table with Leave Feedback per completed order |

### Loyalty System Rules (from `catsy.md` Section 5)

Verify these exact behaviors exist in backend code:

- [ ] 1 stamp per eligible product (admin-configured eligibility)
- [ ] 3×3 grid = 9 slots max, excess stamps queued separately
- [ ] `get_unspent_stamps(limit=9)` or equivalent: returns stamps as `is_spent=False` rows
- [ ] Claim deducts exactly 9, resets card, fills with queued excess
- [ ] Stamp deduction on refund
- [ ] Offline QR scan queued and synced on reconnect (mobile scope)

---

## STEP 5 — Determine What to Build Next

Use this priority order to pick the next task:

### Priority Stack (work top to bottom)

```
1. BLOCKERS — Any runtime crashes, 500 errors, or broken auth? Fix these FIRST.
   → Check DEVELOPMENT_LOG.md for recent issues
   → Run backend: check logs for unhandled exceptions

2. PHASE GAPS — What is the first phase that is not fully complete?
   → Use Step 3 decision table
   → Reference catsy_development_phases.md deliverables checklist for that phase
   → Build missing items one section at a time

3. SPEC VIOLATIONS — Does any implemented feature deviate from catsy.md?
   → Use Step 4 cross-check table
   → Examples: reward items using free text instead of product picker, seat map shown to customers

4. UX GAPS — Phase 5 polish items not yet applied to completed features
   → Missing loading states, empty states, error messages, offline indicator

5. TESTING — Phase 6 integration and security tests
   → Use test_cases.md for test scenarios
   → Use catsy_development_phases.md Section 6.2 security checklist

6. DEPLOYMENT — Phase 7 production setup and mobile handover docs
```

---

## STEP 6 — Before Writing Any Code

1. **Confirm the phase** from Step 3
2. **Confirm the specific deliverable** by re-reading the exact checklist item in `catsy_development_phases.md`
3. **Confirm no spec violation** by re-reading the relevant FR from `catsy.md`
4. **Check `implemented_features.md`** — don't rebuild what already works
5. **Follow SOLID architecture** — new backend logic goes in repositories, not routers; new frontend data-fetching goes in custom hooks, not pages

---

## STEP 7 — After Writing Code

### Double-Check Checklist

```
[ ] Does the new feature match the exact FR in catsy.md?
[ ] Does the backend endpoint match the spec in catsy_development_phases.md section 2.x?
[ ] Does the UI match the button/state tables in catsy_development_phases.md section 3.x or 4.x?
[ ] Is business logic in a repository, not a router?
[ ] Is the frontend hook in src/hooks/, not inside a page component?
[ ] Are error messages sourced from errorMessages.js (not hardcoded strings)?
[ ] Does the feature have loading state, empty state, and error toast?
[ ] Did you add a corresponding entry to DEVELOPMENT_LOG.md summarizing what was changed?
```

### Update the Development Log

After every session, append a new entry to `DEVELOPMENT_LOG.md`:

```markdown
## Session Date: YYYY-MM-DD (Phase X — Feature Name)

### 1. 🏷️ What Was Built / Fixed
**Objective:** One line describing the goal.

- **Files Edited/Created:**
  - `path/to/file.py` (reason)
- **Changes:**
  - Description of what changed and why

### ✅ Summary:
- [x] Checklist item from catsy_development_phases.md
```

---

## STEP 8 — Git Commit

Follow the rules from `MUSTREAD.md`:

```bash
git add .
git commit -m "#ISSUE_NUMBER Exact GitHub Issue Title"
git push
```

- Never commit directly to `main`
- Always branch from `main` for each issue
- Create a PR only when the issue is 100% done

---

## Quick Reference: Phase Completion Summary

| Phase | Status | Source of Truth |
|---|---|---|
| Phase 1 — Setup & Foundation | ✅ Complete | `implemented_features.md` section 1 |
| Phase 2 — Core Backend API | ✅ Complete | `phase3.md` Priority 1+2 verification table |
| Phase 3 — Admin Web Panel | ✅ Complete | `DEVELOPMENT_LOG.md` session 2026-03-26 Phase 3 |
| Phase 4 — Customer Web Portal | ✅ Complete | `DEVELOPMENT_LOG.md` + QA session |
| Phase 5 — UI/UX Polish | ✅ Complete (verified in QA) | `DEVELOPMENT_LOG.md` QA session |
| Phase 6 — Integration & Testing | 🟡 Verify | `test_cases.md` — run full suite |
| Phase 7 — Deployment & Handover | ⏳ Next | `catsy_development_phases.md` section 7 |

> **Current focus: Phase 6 → Phase 7**  
> Run `test_cases.md` integration scenarios. Fix any failures. Then prepare Phase 7 deployment and mobile handover documentation per `catsy_development_phases.md` sections 7.1–7.3.

---

## File Map: Where Everything Lives

```
/mnt/datadrive/Project/Catsy-Final/
├── currentPhases.md                ← ⚡ AI reads this FIRST — current task list (low token)
├── FROZEN.md                       ← 🔒 AI reads this SECOND — do-not-touch list
├── catsy.md                        ← SRS (source of truth for all requirements)
├── catsy_development_phases.md     ← Master build plan (7 phases)
├── implemented_features.md         ← What is done
├── DEVELOPMENT_LOG.md              ← Session history
├── phase3.md                       ← Detailed Phase 3 guide with code
├── test_cases.md                   ← QA test suite
├── MUSTREAD.md                     ← Git/PR team workflow
├── catsy-backend/
│   └── app/
│       ├── routers/                ← HTTP endpoints only (no business logic)
│       ├── repositories/           ← All DB queries and business logic
│       ├── services/               ← Cross-cutting services (auth, email)
│       └── schemas.py              ← ALL Pydantic models (central)
├── catsy-web/
│   └── src/
│       ├── api/                    ← API call functions (one file per domain)
│       ├── components/             ← Reusable UI (ui/) and admin composites (admin/)
│       ├── context/                ← ToastContext, AuthContext
│       ├── hooks/                  ← Custom hooks for all data fetching
│       ├── pages/admin/            ← Admin panel pages
│       ├── pages/                  ← Customer portal pages
│       └── constants/              ← queryKeys.js, errorMessages.js
└── catsy_mobile/
    ├── TECHNICAL_DEBT.md           ← Mobile dev notes
    └── README.md                   ← Mobile setup guide
```
