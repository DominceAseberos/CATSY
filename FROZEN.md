# 🔒 FROZEN — Do Not Modify These Files Without Audit

These files have passed the SOLID principles audit (2026-03-26).
**Before touching any of these, add a DEVELOPMENT_LOG.md entry explaining why.**

---

## ✅ Backend — SOLID Verified (Repository Pattern)

| File | Why Frozen |
|---|---|
| `catsy-backend/app/repositories/orders_repo.py` | SOLID-compliant, DI-verified |
| `catsy-backend/app/repositories/loyalty_repo.py` | SOLID-compliant, stamp overflow logic verified |
| `catsy-backend/app/repositories/cms_repo.py` | SOLID-compliant, TC_SLD_001 passed |
| `catsy-backend/app/repositories/reports_repo.py` | Pure aggregation, TC_SLD_002 passed |
| `catsy-backend/app/repositories/reservations_repo.py` | SOLID-compliant |
| `catsy-backend/app/repositories/rewards_repo.py` | SOLID-compliant, product picker wired |
| `catsy-backend/app/repositories/seats_repo.py` | SOLID-compliant |
| `catsy-backend/app/routers/*.py` | All routers use `Depends(get_repo)` — no raw DB calls |
| `catsy-backend/app/schemas/*.py` | Centralized Pydantic schemas |

---

## ✅ Frontend — Architecture Verified

| File | Why Frozen |
|---|---|
| `catsy-web/src/context/ToastContext.jsx` | Global provider — do not move or rewrap |
| `catsy-web/src/api/apiClient.js` | Global Axios interceptor — HTTP error → Toast mapping is here |
| `catsy-web/src/pages/admin/components/*.jsx` | All admin pages built and wired |
| `catsy-web/src/pages/admin/hooks/*.js` | Custom hooks for data fetching — follow same pattern for new hooks |

---

## ⚠️ Rules for Modifying Frozen Files

1. Log the change in `DEVELOPMENT_LOG.md` first.
2. State the reason (bug fix, spec update, or security patch).
3. If modifying a repository, ensure the router still uses `Depends(get_repo)`.
4. If modifying ToastContext or apiClient, verify all admin pages still render after the change.
5. Never add direct Supabase/DB calls inside a router.
