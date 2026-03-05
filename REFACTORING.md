# POS System – Refactoring & Analysis Report

This document summarizes the full-stack POS analysis, issues found, fixes applied, and recommended structure for ongoing maintenance.

---

## 1. Project Overview

| Layer | Stack | Location |
|-------|--------|----------|
| **Frontend** | Flutter (Dart), Provider, go_router | `lib/` |
| **Backend** | Express (Node.js), SQLite (better-sqlite3) | `server/` |
| **Auth** | Session-style (login returns user; no JWT yet) | Backend open for single superuser |

---

## 2. Issues Detected & Fixes Applied

### 2.1 Frontend

| Issue | Fix |
|-------|-----|
| **Folder name** `lib/screens.dart/` (typo) | Renamed to `lib/screens/` and updated all imports. |
| **Cart screen** `DropdownButtonFormField` used `initialValue` (invalid in Flutter 3) | Replaced with `value: _selectedPaymentMethod`. |
| **Login** connection errors showed raw exception text | Now use `apiErrorMessage(e)` for user-friendly server/connection messages. |
| **ApiService** many calls did not send auth headers | All API calls now use `_authHeaders` (ready for future JWT). |
| **Multipart image upload** did not send Authorization | Added Bearer token to `uploadProductImage` when `AppState.authToken` is set. |

### 2.2 Backend

| Issue | Fix |
|-------|-----|
| **Payment method** Frontend sends `Cash`, `Card`, `Mobile`, `Other`; DB allows only `cash`, `card`, `digital_wallet`, `mixed` | Added `normalizePaymentMethod()` in `server/routes/orders.js`: lowercase + map `Mobile`→`digital_wallet`, `Other`→`mixed`. Used in POST and PATCH. |
| **PATCH /api/orders/:id** returned order without `items` | Response now includes `items` (same shape as GET `/api/orders/:id`) for consistency. |

### 2.3 Auth / Superuser

- Backend **does not issue JWT**; login returns user object only. `AppState.authToken` may be null; all API calls still work because the backend does not require auth yet.
- For a **single superuser with full access**, the app works as-is. When you add JWT:
  - Have `POST /api/auth/login` return a signed token and set `AppState.authToken` in the client.
  - Optionally protect backend routes with a simple middleware that checks `Authorization: Bearer <token>`.

---

## 3. POS Flow Verification

| Flow | Status | Notes |
|------|--------|--------|
| **Sales** | OK | Cart → place order → POST /api/orders; stock decremented; order list/detail work. |
| **Inventory** | OK | Products CRUD, categories, low-stock alerts, stock adjustments. |
| **Payments** | OK | Payment method selected in cart; normalized on backend (cash/card/digital_wallet/mixed). |
| **Reports** | OK | Sales, inventory, top products, user activity, revenue, cashier performance. |
| **Returns / Refunds** | Partial | Order status can be set to `refunded`; no dedicated “return” flow or stock restore yet. |

---

## 4. Recommended Folder Structure

### 4.1 Flutter (`lib/`)

```
lib/
├── main.dart
├── config/
│   └── api_config.dart
├── core/                    # was Core/ – consider lowercase for consistency
│   ├── app_state.dart
│   ├── custom_app_bar.dart
│   └── custom_bottom_nav.dart
├── models/
│   ├── category.dart
│   ├── order.dart
│   ├── product.dart
│   ├── reports.dart
│   ├── stock_adjustment.dart
│   └── user.dart
├── screens/                 # renamed from screens.dart
│   ├── cart_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── order_detail_screen.dart
│   ├── product_form_screen.dart
│   ├── signup_screen.dart
│   └── splash_screen.dart
├── admin/
│   ├── admin_router.dart
│   ├── admin_shell.dart
│   ├── providers/
│   │   └── admin_dashboard_provider.dart
│   └── screens/
│       ├── admin_dashboard_screen.dart
│       ├── admin_products_screen.dart
│       ├── admin_reports_screen.dart
│       ├── admin_sales_screen.dart
│       └── admin_users_screen.dart
├── services/
│   └── api_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    └── category_pills.dart
```

- **Done:** `screens.dart` → `screens`.
- **Optional:** Rename `Core/` → `core/` and update imports for consistent lowercase package paths.

### 4.2 Backend (`server/`)

```
server/
├── index.js
├── db.js
├── lib/
│   ├── auth.js          # if you add JWT later
│   └── safeError.js
├── routes/
│   ├── auth.js
│   ├── categories.js
│   ├── orders.js
│   ├── products.js
│   ├── reports.js
│   └── stock.js
├── scripts/
│   ├── init-db.js
│   └── clear-orders.js
└── uploads/              # product images
```

No structural changes required; routes and scripts are already organized.

---

## 5. Optional Next Steps

1. **Returns/refunds**  
   Add a dedicated “Refund” flow that sets order status to `refunded` and restores product stock (e.g. via `POST /api/stock/adjust` with reason `return` or a dedicated refund endpoint).

2. **JWT auth**  
   Implement token in login response and optional middleware on protected routes; frontend already sends `_authHeaders` everywhere.

3. **Unused dependency**  
   `go_router` is used only in the admin shell; rest of the app uses `Navigator`. Either migrate main app to go_router or keep as-is.

4. **Error handling**  
   Consider a small wrapper in `ApiService` that parses JSON error body once and throws a single type (e.g. `ApiException`) so screens can show `apiErrorMessage()` consistently.

5. **Backend validation**  
   Add request validation (e.g. express-validator or Joi) for POST/PUT/PATCH bodies and return 400 with clear messages.

---

## 6. Summary

- **Frontend:** Screens folder renamed, cart dropdown fixed, login errors improved, ApiService uses `_authHeaders` and sends token on image upload.
- **Backend:** Payment method normalized for orders; PATCH order returns full order with items.
- **POS flows:** Sales, inventory, payments, and reports verified; returns/refunds are partial (status only).
- **Superuser:** Works with full access; add JWT when you need protected API routes.

All changes are backward-compatible and ready for a single superuser with full access.
