# Admin Panel

This folder contains the POS admin panel: dashboard, user management, products & inventory, sales, and reports.

## Structure

- **admin_router.dart** – GoRouter config for admin routes (`/dashboard`, `/users`, `/products`, `/sales`, `/reports`).
- **admin_shell.dart** – Responsive shell: **Drawer** on mobile (< 600px), **NavigationRail** on tablet/desktop. Entry from POS app bar (Admin/Manager only).
- **screens/** – One screen per section; each uses existing `ApiService` with placeholders where the backend is not yet ready.
- **providers/** – Example **Provider** (e.g. `AdminDashboardProvider`) for shared state. Screens currently use local `setState`; for cross-screen or cached data, use Provider/Riverpod/Bloc as suggested below.

## State management

- **Current:** Each admin screen keeps its own state with `setState` and calls `ApiService` in `initState` / on refresh.
- **Suggestion:** For shared or heavier state (e.g. dashboard stats, user list cache), use:
  - **Provider:** Wrap `AdminShell` with `ChangeNotifierProvider`/`FutureProvider` and use `context.watch`/`context.read`. See `providers/admin_dashboard_provider.dart`.
  - **Riverpod:** Define `Provider`/`FutureProvider` in a separate file and use `ref.watch`/`ref.read` in admin screens.
  - **Bloc:** Use `BlocProvider` and `context.read<XBloc>()` for event-driven flows (e.g. user CRUD, filters).

## Responsive behavior

- **&lt; 600px:** Drawer for navigation; lists use `ListView`/cards.
- **≥ 600px:** NavigationRail; tables use `DataTable` where space allows.
- **≥ 800px:** NavigationRail can be `extended` for labels.

## Entry point

Admins and managers see an “Admin Panel” icon in the POS app bar (see `CustomAppBar`). Tapping it pushes `AdminShell`. Back button or “Back to POS” returns to the main app.
