# CATSY POS — Technical Debt Register

> Items logged here are **tracked debt**, not forgotten debt.
> Each entry has an owner, severity, and a suggested next-phase target.
> Close items by linking to the PR or commit that resolves them.

---

## Open Items

### TD-001 — `dartz` → `fpdart` Migration
| Field | Value |
|-------|-------|
| **Severity** | OPTIMIZATION |
| **Phase logged** | Phase 5 |
| **Target phase** | Separate PR (`refactor/fpdart-migration`) |
| **Files affected** | All `*_repository_impl.dart`, `*_repository.dart` interfaces, domain use-cases |
| **Description** | `dartz` is deprecated; `fpdart` is the maintained Dart-idiomatic successor. Migration requires replacing `Either`/`Option` imports and call-sites across ~15 files. Deferred to avoid Phase 5 scope creep. |
| **Effort estimate** | M (half-day) |

---

### TD-002 — Hardcoded Staff ID in Reservation &amp; Loyalty Flows
| Field | Value |
|-------|-------|
| **Severity** | WARNING |
| **Phase logged** | Phase 5 |
| **Target phase** | Phase 6 / auth integration pass |
| **Files affected** | `reservation_card.dart` (L125, L207), `stamp_result_screen.dart` (L74), `claim_reward_screen.dart` (L57) |
| **Description** | `staffId` is hardcoded as `'staff-001'` in several UI widgets. Should be read from `ref.read(authNotifierProvider).staff?.id` once the auth session is stable in all flows. |
| **Effort estimate** | S (2 hours) |

---

### TD-003 — RewardProvider (Riverpod notifier)
| Field | Value |
|-------|-------|
| **Severity** | WARNING |
| **Phase logged** | Phase 5 |
| **Target phase** | Phase 12 (remote reward sync) |
| **Files affected** | `presentation/reward/providers/reward_provider.dart` |
| **Description** | Stub class placeholder. Depends on `RewardRepository` (already implemented) and remote sync. Should become a `NotifierProvider` wrapping reward-query state and exposing `validate`, `claim`, and `sync` actions. |
| **Effort estimate** | M |

---

### TD-004 — LoyaltyProvider (Riverpod notifier)
| Field | Value |
|-------|-------|
| **Severity** | WARNING |
| **Phase logged** | Phase 5 |
| **Target phase** | Phase 9 loyalty-stamp integration |
| **Files affected** | `presentation/loyalty/providers/loyalty_provider.dart` |
| **Description** | Stub class placeholder. Loyalty stamp flow is partially implemented in `stamp_result_screen.dart` using direct `rewardRepository` calls. Should be lifted into a proper notifier to decouple UI from the repository. |
| **Effort estimate** | S |

---

### TD-005 — ProductProvider (order-flow product search/filter)
| Field | Value |
|-------|-------|
| **Severity** | OPTIMIZATION |
| **Phase logged** | Phase 5 |
| **Target phase** | Order-flow Phase |
| **Files affected** | `presentation/order/providers/product_provider.dart` |
| **Description** | Stub class placeholder. Should expose a `StateNotifierProvider` or `NotifierProvider` that wraps `allProductsProvider` with category filtering and search state for the order catalogue screen. |
| **Effort estimate** | S |

---

### TD-006 — PaymentProvider (POS payment flow)
| Field | Value |
|-------|-------|
| **Severity** | WARNING |
| **Phase logged** | Phase 5 |
| **Target phase** | Payment-flow Phase |
| **Files affected** | `presentation/order/providers/payment_provider.dart` |
| **Description** | Stub class placeholder. Should manage payment method selection, split-pay state, and drive `OrderRepository.checkout()`. Adjacent to `OrderSummaryScreen` and `AddonSelectionSheet` which are also placeholder screens. |
| **Effort estimate** | L |

---

### TD-007 — OrderSummaryScreen &amp; AddonSelectionSheet are placeholders
| Field | Value |
|-------|-------|
| **Severity** | WARNING |
| **Phase logged** | Phase 5 |
| **Target phase** | Order-flow Phase |
| **Files affected** | `presentation/order/screens/order_summary_screen.dart`, `presentation/order/screens/addon_selection_sheet.dart` |
| **Description** | Both screens contain only a placeholder `Text(...)`. `OrderSummaryScreen` should render the cart, totals, and a payment CTA. `AddonSelectionSheet` should present available add-ons for a product and wire into `cartProvider.addItem(...)`. |
| **Effort estimate** | L |

---

### TD-008 — `reservation_screen.dart` Create Reservation Dialog
| Field | Value |
|-------|-------|
| **Severity** | OPTIMIZATION |
| **Phase logged** | Phase 5 |
| **Target phase** | Reservation UX Phase |
| **Files affected** | `presentation/reservation/screens/reservation_screen.dart` (L26) |
| **Description** | Comment notes intent to implement a "create reservation" dialog. The `ReservationRepository` already supports inserts. Implement the bottom-sheet form and wire to `reservationControllerProvider`. |
| **Effort estimate** | S |

---

## Closed Items

| ID | Description | Closed in |
|----|-------------|-----------|
| — | Shadow `User` class in `dashboard_provider.dart` | Phase 4 / `refactor/4-state-and-di-cleanup` |
| — | Empty `CartProvider` | Phase 4 / `refactor/4-state-and-di-cleanup` |
| — | Ad-hoc `ConnectivityService()` instantiations | Phase 4 / verified already using provider injection |
| — | Duplicate `secureStorageServiceProvider` in `providers.dart` | Phase 4 / verified no duplicate existed |
| — | `AppConstants.safetyLevel` duplicate of `Env.lowStockSafetyLevel` | Phase 5 / this PR |
