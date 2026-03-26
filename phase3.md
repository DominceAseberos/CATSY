# CUTshier — Phase 3: Admin Web Panel
## Build Guide + Best Practices
**Version:** Based on CUTshier_Dev_Phases_v1.1 | Priority 1+2 verified complete

---

## ✅ Priority 1+2 Verification — All Good

Before Phase 3 starts, here is a quick confirmation that everything from Priority 1+2 maps correctly to the phases doc:

| Task | Phases Doc Requirement | Implementation | Status |
|---|---|---|---|
| Pay endpoint `payment_method` + `change_due` | FR S5, Phase 2.4 `[ADDED]` box | `OrderPayRequest` schema + `pay_order()` service | ✅ |
| `GET /api/staff/orders?status=open` | Phase 2.4 `[ADDED]` box | `status` query param in `OrderRepository.get_all()` | ✅ |
| Inventory auto-deduct/restore | Phase 2.3 + deliverables checklist | `deduct_stock()` / `restore_stock()` in `products_repo.py` | ✅ |
| Stamp overflow carry-over | Phase 2.5 + Golden Rule #4 | `get_unspent_stamps(limit=9)` + `is_spent=False` rows | ✅ verified |
| `POST /loyalty/staff/redeem` | Phase 2.5 | `RewardRedeemRequest` + `mark_reward_redeemed()` | ✅ |
| `GET /api/staff/members?search=` | Phase 2.5 `[ADDED]` box | `customer.py` router, 60/min rate limit, staff JWT | ✅ |
| `DELETE /api/customer/reservations/:id` | Phase 2.6 | Ownership check + 403 on mismatch | ✅ |
| `GET /api/customer/orders` | Phase 2.4 | `customer.py` router, `customer_id` FK on orders | ✅ |
| Reward items table + product picker | Phase 3.3 `[ADDED]` box (spec violation fix) | `reward_items` table, `rewards_repo.py`, `rewards.py` routers | ✅ |

**One open item to verify before Phase 3 demo:** The phases doc Phase 2 deliverables checklist requires `GET /api/admin/apk/download` to return **403 for staff and customer tokens**. This endpoint is not listed in the Priority 1+2 implementation doc — confirm it is either already implemented from before, or add it as a quick task before closing Phase 2. Do not proceed to full Phase 3 without this being verified.

---

## Phase 3 — What to Build

The phases doc defines 11 sections for the Admin Panel. Six are already partially or fully built (Login, Product CRUD, Category CRUD, Materials, Account Manager, Reservation Manager). Five are entirely missing. The reward picker UI backend is done but needs the frontend wired up.

| Section | Doc Reference | Current State | Action |
|---|---|---|---|
| 3.1 Admin Login | `/admin/login` with guard | ✅ Built | Verify staff-blocked message |
| 3.2 Dashboard | Summary cards + notification bell | ❌ Missing | **Build** |
| 3.3 Product Management | CRUD + stamp toggle + reward picker | 🟡 Reward picker UI missing | **Wire up frontend** |
| 3.4 Inventory Management | Table + low-stock highlight + adjust modal | 🟡 Row highlight + reason dropdown unconfirmed | **Verify + fix** |
| 3.5 Employee Management | CRUD + deactivate/reactivate | ✅ Built | Verify state tables |
| 3.6 Reservation Management | Read-only view + filter | ✅ Built | Verify admin is read-only |
| 3.7 Seat Overview | Read-only visual grid (G/R/B) | ❌ Missing | **Build** |
| 3.8 Time Slot Config | List + add/remove + default 5PM–12AM | ❌ Missing | **Build** |
| 3.9 Reports & Analytics | Sales + product + inventory + feedback | ❌ Missing | **Build** |
| 3.10 CMS | Banners + announcements + promos | ❌ Missing | **Build** |
| 3.11 APK Download | Settings > POS App Download, admin-only | ❌ Missing | **Build** |

---

## Project Architecture — Before Writing Any Component

### Folder Structure

```
catsy-web/src/
├── api/                        ← All API call functions (one file per domain)
│   ├── apiClient.js            ← Axios instance (base URL, interceptors)
│   ├── ordersApi.js
│   ├── productsApi.js
│   ├── rewardsApi.js
│   ├── reportsApi.js
│   └── ...
├── components/
│   ├── ui/                     ← Pure reusable UI (no business logic)
│   │   ├── Button.jsx
│   │   ├── Input.jsx
│   │   ├── Modal.jsx
│   │   ├── Toast.jsx
│   │   ├── Table.jsx
│   │   ├── Badge.jsx
│   │   ├── Skeleton.jsx
│   │   ├── ConfirmDialog.jsx
│   │   ├── EmptyState.jsx
│   │   └── Toggle.jsx
│   └── admin/                  ← Admin-specific composite components
│       ├── StatCard.jsx
│       ├── PageHeader.jsx
│       ├── ProductPicker.jsx
│       └── NotificationBell.jsx
├── hooks/                      ← Custom hooks (data fetching, state logic)
│   ├── useProducts.js
│   ├── useReports.js
│   ├── useToast.js
│   ├── useConfirm.js
│   └── ...
├── pages/
│   └── admin/
│       ├── AdminPage.jsx        ← Shell + sidebar
│       ├── DashboardPage.jsx
│       ├── ProductsPage.jsx
│       ├── InventoryPage.jsx
│       ├── ReportsPage.jsx
│       ├── CmsPage.jsx
│       ├── TimeSlotsPage.jsx
│       ├── SeatOverviewPage.jsx
│       └── ApkDownloadPage.jsx
├── context/
│   ├── AuthContext.jsx
│   └── ToastContext.jsx
└── constants/
    ├── queryKeys.js             ← React Query cache keys
    └── errorMessages.js        ← All user-facing error strings
```

---

## Global Error Handling

### 1. Axios Interceptor — `apiClient.js`

Never handle 401/403/500 errors inside individual components. Intercept them globally.

```js
// src/api/apiClient.js
import axios from 'axios';
import { toast } from '../context/ToastContext';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  timeout: 10000,
});

// Request interceptor — attach JWT
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Response interceptor — global error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;
    const code = error.response?.data?.error?.code;

    // Map HTTP status to user-readable message (from phases doc Section 5.9)
    const MESSAGE_MAP = {
      401: 'Your session has expired. Please log in again.',
      403: 'You do not have permission to perform this action.',
      404: 'The requested item could not be found. It may have been deleted.',
      500: 'Something went wrong on our end. Please try again in a moment.',
    };

    if (status === 401) {
      localStorage.removeItem('access_token');
      window.location.href = '/admin/login';
      return Promise.reject(error);
    }

    // 400/422 — field-level errors, let the calling component handle them
    if (status === 400 || status === 422) {
      return Promise.reject(error);
    }

    // All other errors — show a toast globally
    const message = MESSAGE_MAP[status] ?? 'Could not connect. Please check your internet connection.';
    toast.error(message);

    return Promise.reject(error);
  }
);

export default apiClient;
```

### 2. Toast Context — Global Notification System

```jsx
// src/context/ToastContext.jsx
import { createContext, useContext, useState, useCallback } from 'react';

const ToastContext = createContext(null);

// Types: 'success' | 'error' | 'warning' | 'info'
export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const addToast = useCallback((message, type = 'info', duration = 4000) => {
    const id = crypto.randomUUID();
    setToasts(prev => [...prev, { id, message, type }]);
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, duration);
  }, []);

  const toast = {
    success: (msg) => addToast(msg, 'success'),
    error:   (msg) => addToast(msg, 'error'),
    warning: (msg) => addToast(msg, 'warning'),
    info:    (msg) => addToast(msg, 'info'),
  };

  return (
    <ToastContext.Provider value={toast}>
      {children}
      <ToastContainer toasts={toasts} />
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used inside ToastProvider');
  return ctx;
}

// Export a module-level singleton for use inside apiClient (outside React tree)
let _toast = null;
export const toast = {
  success: (msg) => _toast?.success(msg),
  error:   (msg) => _toast?.error(msg),
  warning: (msg) => _toast?.warning(msg),
  info:    (msg) => _toast?.info(msg),
  _register: (instance) => { _toast = instance; },
};
```

### 3. Error Constants — Never Hard-code Strings

```js
// src/constants/errorMessages.js
export const ERROR_MESSAGES = {
  REQUIRED_FIELD:     'This field is required.',
  INVALID_EMAIL:      'Please enter a valid email address.',
  PASSWORD_TOO_SHORT: 'Password must be at least 8 characters.',
  INVALID_PRICE:      'Please enter a valid price (e.g., 120 or 120.50).',
  NEGATIVE_STOCK:     'Quantity cannot be negative.',
  GUEST_COUNT_RANGE:  'Number of guests must be between 1 and 10.',
  CASH_UNDERPAYMENT:  'Amount tendered must be equal to or greater than the total.',
  EMAIL_EXISTS:       'An account with this email already exists.',
  WRONG_CREDENTIALS:  'Incorrect email or password.',
  NO_ADMIN_ACCESS:    'You do not have admin access.',
};
```

---

## Reusable UI Components

### SOLID Principle Applied: Single Responsibility + Open/Closed

Each UI component does **one thing**. It accepts props to extend behavior — it does not contain business logic.

### Button.jsx

```jsx
// src/components/ui/Button.jsx
// Covers all button states from phases doc Section 5.1

const VARIANTS = {
  primary:   'bg-blue-600 text-white hover:bg-blue-700',
  danger:    'bg-red-600 text-white hover:bg-red-700',
  success:   'bg-green-600 text-white hover:bg-green-700',
  outline:   'border border-gray-300 text-gray-700 hover:bg-gray-50',
  ghost:     'text-gray-600 hover:bg-gray-100',
};

export function Button({
  children,
  variant = 'primary',
  loading = false,
  disabled = false,
  onClick,
  type = 'button',
  className = '',
}) {
  const isDisabled = disabled || loading;

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={isDisabled}
      className={`
        inline-flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium
        transition-all duration-150
        ${VARIANTS[variant]}
        ${isDisabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer active:scale-[0.98]'}
        ${className}
      `}
    >
      {loading && (
        <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/>
        </svg>
      )}
      {loading ? `${children}...` : children}
    </button>
  );
}
```

### Modal.jsx

```jsx
// src/components/ui/Modal.jsx
// Single-responsibility: render a modal shell. Content goes in children.

import { useEffect } from 'react';

export function Modal({ isOpen, onClose, title, children, size = 'md' }) {
  const SIZE_MAP = { sm: 'max-w-sm', md: 'max-w-lg', lg: 'max-w-2xl' };

  // Close on Escape key
  useEffect(() => {
    const handler = (e) => { if (e.key === 'Escape') onClose(); };
    if (isOpen) document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/40"
        onClick={onClose}
        aria-hidden="true"
      />
      {/* Panel */}
      <div className={`relative bg-white rounded-xl shadow-lg w-full ${SIZE_MAP[size]} mx-4 p-6`}>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
            aria-label="Close"
          >
            ✕
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}
```

### ConfirmDialog.jsx

```jsx
// src/components/ui/ConfirmDialog.jsx
// Used for destructive actions (delete product, deactivate employee, cancel reservation)
// Reference: phases doc Section 5.8

import { Modal } from './Modal';
import { Button } from './Button';

export function ConfirmDialog({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmLabel = 'Confirm',
  confirmVariant = 'danger',
  loading = false,
}) {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} size="sm">
      <p className="text-sm text-gray-600 mb-6">{message}</p>
      <div className="flex justify-end gap-3">
        <Button variant="outline" onClick={onClose} disabled={loading}>
          Cancel
        </Button>
        <Button variant={confirmVariant} onClick={onConfirm} loading={loading}>
          {confirmLabel}
        </Button>
      </div>
    </Modal>
  );
}
```

### useConfirm hook

```js
// src/hooks/useConfirm.js
// Encapsulates the open/close/loading state for ConfirmDialog
// Interface Segregation: consumers only get what they need

import { useState, useCallback } from 'react';

export function useConfirm() {
  const [state, setState] = useState({
    isOpen: false,
    loading: false,
    title: '',
    message: '',
    onConfirm: null,
  });

  const confirm = useCallback(({ title, message, onConfirm }) => {
    setState({ isOpen: true, loading: false, title, message, onConfirm });
  }, []);

  const handleConfirm = useCallback(async () => {
    setState(s => ({ ...s, loading: true }));
    try {
      await state.onConfirm?.();
      setState(s => ({ ...s, isOpen: false, loading: false }));
    } catch {
      setState(s => ({ ...s, loading: false }));
    }
  }, [state]);

  const handleClose = useCallback(() => {
    if (!state.loading) setState(s => ({ ...s, isOpen: false }));
  }, [state.loading]);

  return { confirmState: state, confirm, handleConfirm, handleClose };
}
```

### EmptyState.jsx

```jsx
// src/components/ui/EmptyState.jsx
// Covers all empty state cases from phases doc Section 5.6

export function EmptyState({ icon = '📋', message, action }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <span className="text-4xl mb-3" aria-hidden="true">{icon}</span>
      <p className="text-sm text-gray-500 max-w-xs">{message}</p>
      {action && (
        <div className="mt-4">{action}</div>
      )}
    </div>
  );
}
```

### Skeleton.jsx

```jsx
// src/components/ui/Skeleton.jsx
// Covers loading states from phases doc Section 5.5

export function Skeleton({ className = '' }) {
  return (
    <div className={`animate-pulse bg-gray-200 rounded ${className}`} />
  );
}

export function TableSkeleton({ rows = 5, cols = 4 }) {
  return (
    <div className="space-y-2">
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="flex gap-4">
          {Array.from({ length: cols }).map((_, j) => (
            <Skeleton key={j} className="h-8 flex-1" />
          ))}
        </div>
      ))}
    </div>
  );
}
```

### ProductPicker.jsx — Reusable searchable dropdown

```jsx
// src/components/admin/ProductPicker.jsx
// Used in reward items form (Phase 3.3 [ADDED] requirement)
// SOLID: Single responsibility — picking a product. No form logic inside.

import { useState } from 'react';
import { useProducts } from '../../hooks/useProducts';

export function ProductPicker({ value, onChange, placeholder = 'Search products...' }) {
  const [query, setQuery] = useState('');
  const { products, isLoading } = useProducts();

  const filtered = products?.filter(p =>
    p.product_name.toLowerCase().includes(query.toLowerCase())
  ) ?? [];

  const selected = products?.find(p => p.product_id === value);

  return (
    <div className="relative">
      <input
        type="text"
        value={query || selected?.product_name || ''}
        onChange={(e) => { setQuery(e.target.value); onChange(null); }}
        placeholder={placeholder}
        className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      {query && (
        <div className="absolute z-10 mt-1 w-full bg-white border border-gray-200 rounded-lg shadow-lg max-h-52 overflow-y-auto">
          {isLoading && <div className="p-3 text-sm text-gray-400">Loading...</div>}
          {!isLoading && filtered.length === 0 && (
            <div className="p-3 text-sm text-gray-400">No products found.</div>
          )}
          {filtered.map(product => (
            <button
              key={product.product_id}
              type="button"
              onClick={() => { onChange(product.product_id); setQuery(''); }}
              className="w-full text-left px-3 py-2 text-sm hover:bg-gray-50 flex items-center gap-3"
            >
              {product.product_image && (
                <img src={product.product_image} alt="" className="w-8 h-8 rounded object-cover" />
              )}
              <div>
                <p className="font-medium text-gray-900">{product.product_name}</p>
                <p className="text-xs text-gray-400">{product.category_name}</p>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
```

---

## Data Fetching — Custom Hooks (Dependency Inversion Principle)

Pages depend on hooks, not on API calls directly. Hooks depend on the API layer, not on Axios directly. This means you can swap the API layer without touching pages.

```js
// src/hooks/useProducts.js
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { QUERY_KEYS } from '../constants/queryKeys';
import * as productsApi from '../api/productsApi';
import { useToast } from '../context/ToastContext';

export function useProducts() {
  return useQuery({
    queryKey: [QUERY_KEYS.PRODUCTS],
    queryFn: productsApi.getAll,
    staleTime: 30_000,
  });
}

export function useDeleteProduct() {
  const queryClient = useQueryClient();
  const toast = useToast();

  return useMutation({
    mutationFn: productsApi.deleteProduct,
    onSuccess: () => {
      queryClient.invalidateQueries([QUERY_KEYS.PRODUCTS]);
      toast.success('Product deleted successfully.');
    },
    onError: (error) => {
      // 400/422 field errors are handled here; 401/403/500 already handled by interceptor
      const msg = error.response?.data?.error?.message ?? 'Failed to delete product.';
      toast.error(msg);
    },
  });
}
```

```js
// src/constants/queryKeys.js
export const QUERY_KEYS = {
  PRODUCTS:       'products',
  CATEGORIES:     'categories',
  INVENTORY:      'inventory',
  ORDERS:         'orders',
  RESERVATIONS:   'reservations',
  REPORTS_SALES:  'reports_sales',
  REPORTS_PRODUCTS: 'reports_products',
  TIME_SLOTS:     'time_slots',
  REWARD_ITEMS:   'reward_items',
  NOTIFICATIONS:  'notifications',
  CMS:            'cms',
};
```

---

## Phase 3 — Section-by-Section Build Guide

### 3.2 Admin Dashboard

**Required by phases doc:** Summary cards (Today's Sales, Orders Today, Low Stock Alerts count, Pending Reservations), quick links, notification bell with badge count.

```jsx
// src/pages/admin/DashboardPage.jsx
import { useQuery } from '@tanstack/react-query';
import { StatCard } from '../../components/admin/StatCard';
import { Skeleton } from '../../components/ui/Skeleton';
import apiClient from '../../api/apiClient';

function useDashboardStats() {
  return useQuery({
    queryKey: ['dashboard_stats'],
    queryFn: async () => {
      const [sales, orders, lowStock, reservations] = await Promise.all([
        apiClient.get('/api/admin/reports/sales?period=today'),
        apiClient.get('/api/admin/orders?period=today'),
        apiClient.get('/api/admin/inventory/low-stock'),
        apiClient.get('/api/staff/reservations?status=pending'),
      ]);
      return {
        todaySales:          sales.data.data.total ?? 0,
        ordersToday:         orders.data.data.length ?? 0,
        lowStockCount:       lowStock.data.data.length ?? 0,
        pendingReservations: reservations.data.data.length ?? 0,
      };
    },
    refetchInterval: 60_000, // refresh every 60s
  });
}

export function DashboardPage() {
  const { data, isLoading } = useDashboardStats();

  if (isLoading) {
    return (
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton key={i} className="h-24 rounded-xl" />
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard
          label="Today's Sales"
          value={`₱${data.todaySales.toLocaleString()}`}
          link="/admin/reports"
          linkLabel="View Reports"
        />
        <StatCard
          label="Orders Today"
          value={data.ordersToday}
          link="/admin/orders"
          linkLabel="View Orders"
        />
        <StatCard
          label="Low Stock Alerts"
          value={data.lowStockCount}
          link="/admin/inventory"
          linkLabel="View Inventory"
          alert={data.lowStockCount > 0}
        />
        <StatCard
          label="Pending Reservations"
          value={data.pendingReservations}
          link="/admin/reservations"
          linkLabel="Manage Reservations"
          alert={data.pendingReservations > 0}
        />
      </div>
    </div>
  );
}
```

```jsx
// src/components/admin/StatCard.jsx
import { Link } from 'react-router-dom';

export function StatCard({ label, value, link, linkLabel, alert = false }) {
  return (
    <div className={`bg-white rounded-xl border p-4 ${alert ? 'border-orange-300' : 'border-gray-200'}`}>
      <p className="text-xs text-gray-500 mb-1">{label}</p>
      <p className={`text-2xl font-semibold ${alert ? 'text-orange-600' : 'text-gray-900'}`}>
        {value}
      </p>
      {link && (
        <Link to={link} className="text-xs text-blue-600 hover:underline mt-2 block">
          {linkLabel} →
        </Link>
      )}
    </div>
  );
}
```

---

### 3.3 Reward Product Picker UI (Backend Done — Needs Frontend)

The `rewards_repo.py` and `rewards.py` routers are complete from Priority 2. Now wire the admin UI.

Add a **Reward Items** section to `ProductsPage.jsx` (or its own tab):

```jsx
// Add to ProductsPage or create RewardItemsSection.jsx
import { ProductPicker } from '../../components/admin/ProductPicker';
import { useToast } from '../../context/ToastContext';
import { useConfirm } from '../../hooks/useConfirm';
import apiClient from '../../api/apiClient';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

function useRewardItems() {
  return useQuery({
    queryKey: ['reward_items'],
    queryFn: () => apiClient.get('/api/admin/rewards').then(r => r.data.data),
  });
}

export function RewardItemsSection() {
  const { data: rewardItems, isLoading } = useRewardItems();
  const queryClient = useQueryClient();
  const toast = useToast();
  const { confirmState, confirm, handleConfirm, handleClose } = useConfirm();
  const [selectedProductId, setSelectedProductId] = useState(null);

  const addMutation = useMutation({
    mutationFn: (product_id) => apiClient.post('/api/admin/rewards', { product_id }),
    onSuccess: () => {
      queryClient.invalidateQueries(['reward_items']);
      toast.success('Reward item added.');
      setSelectedProductId(null);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => apiClient.delete(`/api/admin/rewards/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries(['reward_items']);
      toast.success('Reward item removed.');
    },
  });

  return (
    <div>
      <h3 className="text-sm font-semibold text-gray-700 mb-3">Reward Items</h3>

      {/* Product picker — requirement from phases doc [ADDED] FR A3 */}
      <div className="flex gap-2 mb-4">
        <div className="flex-1">
          <ProductPicker
            value={selectedProductId}
            onChange={setSelectedProductId}
            placeholder="Search products to add as reward..."
          />
        </div>
        <Button
          onClick={() => addMutation.mutate(selectedProductId)}
          disabled={!selectedProductId}
          loading={addMutation.isPending}
        >
          Add Reward
        </Button>
      </div>

      {/* Reward items list */}
      {isLoading && <TableSkeleton rows={3} cols={3} />}
      {!isLoading && rewardItems?.length === 0 && (
        <EmptyState icon="🎁" message="No reward items yet. Add a product above." />
      )}
      {rewardItems?.map(item => (
        <div key={item.id} className="flex items-center justify-between py-2 border-b border-gray-100">
          <div className="flex items-center gap-3">
            {item.products?.product_image && (
              <img src={item.products.product_image} className="w-8 h-8 rounded object-cover" alt="" />
            )}
            <div>
              <p className="text-sm font-medium">{item.products?.product_name}</p>
              <p className="text-xs text-gray-400">{item.products?.category_name}</p>
            </div>
          </div>
          <Button
            variant="ghost"
            onClick={() => confirm({
              title: 'Remove reward item',
              message: `Remove "${item.products?.product_name}" from rewards? Customers will no longer be able to claim this.`,
              onConfirm: () => deleteMutation.mutateAsync(item.id),
            })}
          >
            Remove
          </Button>
        </div>
      ))}

      <ConfirmDialog {...confirmState} onClose={handleClose} onConfirm={handleConfirm} />
    </div>
  );
}
```

---

### 3.4 Inventory — Verify These Two Items

Before moving forward, check `MaterialList.jsx` for the following — they are in the phases doc deliverables but were listed as unconfirmed:

**a) Low-stock row highlighting (required):**
```jsx
// In your inventory table row — add conditional class
<tr className={item.material_stock <= item.minimum_threshold ? 'bg-red-50' : ''}>
  <td>
    {item.material_stock <= item.minimum_threshold && (
      <span className="text-xs font-medium text-red-600 bg-red-100 px-2 py-0.5 rounded-full">
        LOW
      </span>
    )}
    {item.material_stock === 0 && (
      <span className="text-xs font-medium text-red-800 bg-red-200 px-2 py-0.5 rounded-full">
        OUT OF STOCK
      </span>
    )}
  </td>
</tr>
```

**b) Adjust modal reason dropdown (required by phases doc):**
The phases doc requires a reason dropdown with these exact options: `Restock`, `Damaged`, `Incorrect Count`. Make sure this is in the adjust modal, not just a quantity field.

---

### 3.7 Seat Overview

The phases doc requires a read-only visual grid with color coding (Green = Available, Red = Occupied, Blue = Reserved) and a tooltip on reserved seats showing customer name, time slot, and guest count.

```jsx
// src/pages/admin/SeatOverviewPage.jsx
import { useQuery } from '@tanstack/react-query';
import apiClient from '../../api/apiClient';

const STATUS_STYLES = {
  available: { bg: 'bg-green-100 border-green-400', label: 'text-green-700', dot: 'bg-green-500' },
  occupied:  { bg: 'bg-red-100 border-red-400',   label: 'text-red-700',   dot: 'bg-red-500'   },
  reserved:  { bg: 'bg-blue-100 border-blue-400', label: 'text-blue-700',  dot: 'bg-blue-500'  },
};

export function SeatOverviewPage() {
  const { data: seats, isLoading } = useQuery({
    queryKey: ['seats'],
    queryFn: () => apiClient.get('/api/seats').then(r => r.data.data),
    refetchInterval: 30_000,
  });

  return (
    <div>
      {/* Legend */}
      <div className="flex gap-4 mb-4 text-xs text-gray-500">
        {Object.entries(STATUS_STYLES).map(([status, s]) => (
          <span key={status} className="flex items-center gap-1 capitalize">
            <span className={`w-3 h-3 rounded-full ${s.dot}`} />
            {status}
          </span>
        ))}
      </div>

      <p className="text-xs text-gray-400 mb-4 italic">
        Seat state is managed by staff on the mobile app.
      </p>

      {isLoading && <div className="grid grid-cols-5 gap-3"><TableSkeleton rows={2} cols={5} /></div>}

      <div className="grid grid-cols-3 sm:grid-cols-5 gap-3">
        {seats?.map(seat => {
          const style = STATUS_STYLES[seat.status] ?? STATUS_STYLES.available;
          return (
            <div
              key={seat.id}
              className={`relative group border-2 rounded-xl p-3 text-center ${style.bg}`}
            >
              <p className={`text-sm font-semibold ${style.label}`}>Seat {seat.seat_number}</p>
              <p className={`text-xs capitalize ${style.label}`}>{seat.status}</p>

              {/* Tooltip on reserved seats */}
              {seat.status === 'reserved' && seat.reservation && (
                <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 z-10
                  hidden group-hover:block bg-gray-900 text-white text-xs rounded-lg p-2 w-40 shadow-lg">
                  <p className="font-medium">{seat.reservation.customer_name ?? 'Guest'}</p>
                  <p>{seat.reservation.time_slot}</p>
                  <p>{seat.reservation.guest_count} guest(s)</p>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

---

### 3.8 Time Slot Configuration

The phases doc requires pre-seeded defaults on first run with a banner, and a warning when removing a slot with pending reservations.

```jsx
// src/pages/admin/TimeSlotsPage.jsx

const DEFAULT_SLOTS = ['5:00 PM','6:00 PM','7:00 PM','8:00 PM','9:00 PM','10:00 PM','11:00 PM','12:00 AM'];

export function TimeSlotsPage() {
  const { data: slots, isLoading } = useQuery({
    queryKey: ['time_slots'],
    queryFn: () => apiClient.get('/api/admin/time-slots').then(r => r.data.data),
  });
  const toast = useToast();
  const queryClient = useQueryClient();
  const { confirmState, confirm, handleConfirm, handleClose } = useConfirm();

  const isFirstRun = slots?.length === 0;

  const addMutation = useMutation({
    mutationFn: (time) => apiClient.post('/api/admin/time-slots', { time }),
    onSuccess: () => {
      queryClient.invalidateQueries(['time_slots']);
      toast.success('Time slot added.');
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => apiClient.delete(`/api/admin/time-slots/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries(['time_slots']);
      toast.success('Time slot removed.');
    },
  });

  const handleDelete = (slot) => {
    const warningMsg = slot.pending_count > 0
      ? `There are ${slot.pending_count} pending reservation(s) in this slot. Removing it will affect those customers.`
      : `Remove the ${slot.time} time slot?`;

    confirm({
      title: 'Remove time slot',
      message: warningMsg,
      confirmLabel: 'Remove',
      onConfirm: () => deleteMutation.mutateAsync(slot.id),
    });
  };

  return (
    <div className="max-w-lg">
      {/* First-run banner — required by phases doc [ADDED] */}
      {isFirstRun && (
        <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 mb-4 text-sm text-blue-700">
          These are the default operating hours. Edit or remove slots as needed.
          <div className="flex flex-wrap gap-2 mt-3">
            {DEFAULT_SLOTS.map(slot => (
              <button
                key={slot}
                onClick={() => addMutation.mutate(slot)}
                className="px-3 py-1 bg-blue-100 hover:bg-blue-200 text-blue-800 text-xs rounded-full"
              >
                + {slot}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Slots list */}
      {slots?.map(slot => (
        <div key={slot.id} className="flex items-center justify-between py-3 border-b border-gray-100">
          <span className="text-sm font-medium text-gray-800">{slot.time}</span>
          {slot.pending_count > 0 && (
            <span className="text-xs text-orange-600 bg-orange-50 px-2 py-0.5 rounded-full mr-auto ml-3">
              {slot.pending_count} pending
            </span>
          )}
          <Button variant="ghost" onClick={() => handleDelete(slot)}>Remove</Button>
        </div>
      ))}

      <ConfirmDialog {...confirmState} onClose={handleClose} onConfirm={handleConfirm} />
    </div>
  );
}
```

---

### 3.9 Reports & Analytics

The phases doc requires: date range picker, chart (bar/line), table with daily totals including payment method breakdown (Cash / GCash / Maya), export to PDF/CSV, product analysis, inventory depletion, and feedback viewer.

**Backend first:** Make sure these endpoints exist before building the UI:
- `GET /api/admin/reports/sales?from=&to=`
- `GET /api/admin/reports/products`
- `GET /api/admin/reports/inventory`
- `GET /api/admin/feedback`

```jsx
// src/hooks/useReports.js
export function useSalesReport({ from, to }) {
  return useQuery({
    queryKey: ['reports_sales', from, to],
    queryFn: () =>
      apiClient
        .get('/api/admin/reports/sales', { params: { from, to } })
        .then(r => r.data.data),
    enabled: !!from && !!to,
  });
}
```

**Payment method breakdown table** (required by phases doc 3.9):
```jsx
// Inside ReportsPage — sales table must include payment method split
<table className="w-full text-sm">
  <thead>
    <tr className="text-left text-xs text-gray-500 border-b">
      <th className="pb-2">Date</th>
      <th className="pb-2 text-right">Total</th>
      <th className="pb-2 text-right">Cash</th>
      <th className="pb-2 text-right">GCash</th>
      <th className="pb-2 text-right">Maya</th>
      <th className="pb-2 text-right">Orders</th>
    </tr>
  </thead>
  <tbody>
    {salesData?.daily.map(row => (
      <tr key={row.date} className="border-b border-gray-50">
        <td className="py-2">{row.date}</td>
        <td className="py-2 text-right font-medium">₱{row.total.toLocaleString()}</td>
        <td className="py-2 text-right text-gray-500">₱{row.cash.toLocaleString()}</td>
        <td className="py-2 text-right text-gray-500">₱{row.gcash.toLocaleString()}</td>
        <td className="py-2 text-right text-gray-500">₱{row.maya.toLocaleString()}</td>
        <td className="py-2 text-right">{row.order_count}</td>
      </tr>
    ))}
  </tbody>
</table>
```

---

### 3.10 CMS — Banners, Announcements, Promos

**Backend needed first.** From the phases doc, CMS has no backend or frontend currently. Build the backend router first:

```
GET/POST/PUT/DELETE /api/admin/cms
```

Then the frontend:

```jsx
// CmsPage pattern — same CRUD pattern as products
// Each CMS item: type ('banner' | 'announcement' | 'promo'), title, body, image, active toggle, start/end date

// Key requirement from phases doc: all CMS changes reflect immediately on the customer portal
// Achieve this by React Query invalidating the public CMS query on every mutation
```

---

### 3.11 APK Download Section

The phases doc (Phase 2 `[ADDED]` and Phase 3.11) defines this exactly:

```jsx
// src/pages/admin/ApkDownloadPage.jsx
// Route: accessible from Settings > POS App Download sidebar item
// Visible to admin only — do not render for staff accounts

import { useState } from 'react';
import { Button } from '../../components/ui/Button';
import apiClient from '../../api/apiClient';

export function ApkDownloadPage() {
  const [downloading, setDownloading] = useState(false);
  const toast = useToast();

  const handleDownload = async () => {
    setDownloading(true);
    try {
      const response = await apiClient.get('/api/admin/apk/download', {
        responseType: 'blob',
      });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', 'catsy-pos.apk');
      document.body.appendChild(link);
      link.click();
      link.remove();
      toast.success('APK download started.');
    } catch {
      // 401/403/500 already handled by interceptor
    } finally {
      setDownloading(false);
    }
  };

  return (
    <div className="max-w-md">
      <h2 className="text-lg font-semibold text-gray-900 mb-1">POS App Download</h2>
      <p className="text-sm text-gray-500 mb-6">
        Install this APK on the staff Android handheld device.
      </p>

      {/* APK metadata — fetch from endpoint or config */}
      <div className="bg-gray-50 border border-gray-200 rounded-xl p-4 mb-6 space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-gray-500">Version</span>
          <span className="font-medium text-gray-900">1.0.0</span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-500">Last updated</span>
          <span className="font-medium text-gray-900">—</span>
        </div>
      </div>

      <Button onClick={handleDownload} loading={downloading}>
        Download POS App (APK)
      </Button>
    </div>
  );
}
```

---

## SOLID Principles Applied — Summary

| Principle | How It Applies in This Codebase |
|---|---|
| **Single Responsibility** | `Button` only renders a button. `useConfirm` only manages confirm state. `apiClient` only handles HTTP. Never mix concerns. |
| **Open/Closed** | `Button` is extended via `variant` prop — add a new variant without touching the component. `StatCard` is extended via `alert` prop. |
| **Liskov Substitution** | All page-level data hooks (`useProducts`, `useReports`) return the same shape: `{ data, isLoading, isError }`. Pages treat them interchangeably. |
| **Interface Segregation** | `useConfirm` gives callers exactly `confirm()`, `handleConfirm`, `handleClose`, `confirmState` — nothing extra. `ProductPicker` only cares about `value` and `onChange`. |
| **Dependency Inversion** | Pages depend on hooks. Hooks depend on the `api/` layer. The `api/` layer depends on `apiClient`. Nothing calls Axios directly in a page or component. |

---

## Phase 3 Deliverables Checklist

From phases doc — everything that must be ✅ before Phase 4 starts:

- [ ] Admin can log in and access all sections
- [ ] Product CRUD works end-to-end including stamp eligibility toggle
- [ ] Reward items section uses product picker — not free-text form (**spec requirement**)
- [ ] Inventory adjustments persist and low-stock alerts trigger correctly (red row + LOW badge)
- [ ] Reports load real data including **payment method breakdown** (Cash / GCash / Maya)
- [ ] Time slot config page pre-populated with default 5PM–12AM slots on first run
- [ ] APK download section visible and functional for admin only (staff returns 403)
- [ ] CMS content published by admin appears on the customer portal
- [ ] All button states and error messages implemented

---

*End of Phase 3 Build Guide*