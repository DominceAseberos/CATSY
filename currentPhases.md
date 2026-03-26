# 📍 CUTshier — Current Project State
> **AI: Read THIS file first. Do not load catsy_development_phases.md unless resolving a spec dispute.**
> Last updated: 2026-03-27

> [!IMPORTANT]
> **AI Rules — What You Auto-Update vs What You Wait For**
>
> | Action | Who Does It |
> |---|---|
> | `test_cases.md` — Actual Outcome + Status columns | **Human only.** AI never assumes a test passed. Wait for the user to confirm. |
> | `DEVELOPMENT_LOG.md` — New session entry | **AI** — after every coding session, before committing. |
> | `currentPhases.md` — Tick off completed tasks | **AI** — after a task is verified by the user. |
> | `FROZEN.md` | **Never modified** by AI unless user explicitly requests an audit. |
> | `catsy_development_phases.md`, `catsy.md`, `phase3.md` | **AI reads only** — never modifies these spec files. |

---

## ✅ COMPLETED (Do Not Rebuild)

| Area | Status |
|---|---|
| Phase 1 — Foundation | Done |
| Phase 2 — Backend API | Done — all endpoints live |
| Phase 3 — Admin Panel | Done — all 11 sections built |
| Phase 4 — Customer Portal | Done — reservation, stamps, QR, history |
| Phase 5 — UI/UX Polish | Done — ToastProvider fixed, skeletons, loading states |
| SOLID Backend Refactor | Done — all repos isolated, DI enforced |
| DB Seeding | Done — products, categories, orders, stamps seeded |
| Reservation Cancellation | Done — cancel button implemented |

---

## 🔄 ACTIVE — Phase 6: Integration & Testing

### Pending Tasks (run in this order)
- [ ] Create a staff test account
- [ ] Run `TC_ATH_003` — staff login blocked from admin portal
- [ ] Run `TC_SEC_001` — staff token returns 403 on APK endpoint
- [ ] Run `TC_DSH_001` — Dashboard stat cards match order history
- [ ] Run `TC_DSH_002` — Low stock alert triggers correctly
- [ ] Run `TC_RPT_001` — Date filter on Reports
- [ ] Run `TC_RPT_002` — Payment method breakdown (Cash/GCash/Maya)
- [ ] Run `TC_INV_001` — Inventory Restock adjustment
- [ ] Run `TC_PRD_001` — Reward picker (product dropdown only)
- [ ] Run `TC_PRD_002` — Stamp eligible toggle
- [ ] Run `TC_FBC_001` — Customer feedback appears in admin Reports
- [ ] Run `TC_UIX_001` — 500 error shows red toast
- [ ] Run `TC_ATH_004` — Admin logout (logout button missing from admin panel)
- [ ] Security audit: run all checks in `catsy_development_phases.md` Section 6.2
- [ ] Cross-browser: Chrome, Firefox, Safari, Edge (Section 6.3)

### Known Issues
| Issue | File | Priority |
|---|---|---|
| Admin panel has no logout button/profile icon | `AdminPage.jsx` or `AdminHeader.jsx` | HIGH |
| Nav menu mobile slide has no animation | Customer portal nav | LOW |
| Loading dots don't animate incrementally (`. .. ...`) | Login button | LOW |

---

## ⏭️ NEXT — Phase 7: Deployment & Handover

**Do not start until all Phase 6 test cases pass.**

- [ ] Deploy backend to production (VPS/cloud)
- [ ] Deploy admin panel + customer portal
- [ ] Run DB migrations on production
- [ ] Set all environment variables (never commit `.env`)
- [ ] Create admin account for café owner
- [ ] Export Postman collection
- [ ] Write `/docs/mobile-sqlite-schema.md` for mobile dev handover
- [ ] Write mobile developer API handover guide

---

## 🧭 Context Map (What to Read for Each Task)

| Task | Read This | Skip This |
|---|---|---|
| Fixing a bug | `FROZEN.md` + `DEVELOPMENT_LOG.md` | `catsy_development_phases.md` |
| Running tests | `test_cases.md` sections only | Phase 1–5 docs |
| Adding a new feature | `catsy.md` FR section + `FROZEN.md` | Phase 1–4 docs |
| Phase 7 deployment | `catsy_development_phases.md` Section 7 only | All other sections |
| Handover docs | `catsy_development_phases.md` Section 7.2–7.3 only | Everything else |