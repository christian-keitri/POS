# POS API (Node.js + SQLite)

Backend for the POS Flutter app. Provides a REST API over a SQLite database for **products**, **categories**, and **orders**.

## Setup

```bash
cd server
npm install
npm run init-db   # creates database and seed data
npm start         # or npm run dev for auto-reload
```

Server runs at **http://localhost:3000** by default. Set `PORT` in `.env` to change.

## Database

- **File:** `server/data/pos.db` (SQLite)
- **Tables:** `users`, `categories`, `products`, `orders`, `order_items`
- **Init:** `npm run init-db` creates the schema, runs migrations for existing DBs, and seeds sample products (Coffee, Tea, Chips, Milk, Water).

**Schema highlights:**
- **users** – `updated_at`; **categories** – `description`, `sort_order` (for display order)
- **products** – `barcode`, `description`, `is_active` (soft disable), `image_path`
- **orders** – `cashier_id` (FK to users), `payment_method`, `notes`, `updated_at`
- Indexes on product name/active, order status/cashier, and order_items.product_id for faster queries.

## API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/categories` | List categories (by sort_order, name) |
| GET | `/api/products` | List products (optional `?category_id=`, `?active_only=1`) |
| GET | `/api/products/:id` | Get one product |
| POST | `/api/products` | Create product |
| PUT | `/api/products/:id` | Update product |
| DELETE | `/api/products/:id` | Delete product |
| GET | `/api/orders` | List orders (optional `?user_id=`, `?status=`) |
| GET | `/api/orders/stats` | Today’s order count and revenue |
| GET | `/api/orders/:id` | Get order with line items |
| POST | `/api/orders` | Create order |
| PATCH | `/api/orders/:id` | Update order (status, payment_method, notes) |
| POST | `/api/auth/signup` | Create user account |
| POST | `/api/auth/login` | Login, returns user |
| GET | `/api/auth/users` | List all users (no passwords) |

### Create product (POST /api/products)

```json
{
  "name": "Espresso",
  "sku": "SKU-006",
  "barcode": "5901234123457",
  "description": "Single shot",
  "price": 2.50,
  "cost": 0.60,
  "stock": 50,
  "category_id": 1,
  "is_active": 1
}
```

### Create order (POST /api/orders)

```json
{
  "user_id": "optional-user-id",
  "cashier_id": 1,
  "payment_method": "card",
  "notes": "Table 3",
  "items": [
    { "product_id": 1, "quantity": 2 },
    { "product_id": 3, "quantity": 1 }
  ]
}
```

### Update order (PATCH /api/orders/:id)

```json
{ "status": "completed", "payment_method": "cash", "notes": "Paid in full" }
```
`status`: `pending` | `completed` | `cancelled`

## Using from Flutter

Point your app to `http://localhost:3000` (or your deployed URL) for products and orders.
