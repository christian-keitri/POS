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
- **Tables:** `categories`, `products`, `orders`, `order_items`
- **Init:** `npm run init-db` creates the schema and sample products (Coffee, Tea, Chips, Milk, Water).

## API

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/categories` | List categories |
| GET | `/api/products` | List products (optional `?category_id=`) |
| GET | `/api/products/:id` | Get one product |
| POST | `/api/products` | Create product |
| PUT | `/api/products/:id` | Update product |
| DELETE | `/api/products/:id` | Delete product |
| GET | `/api/orders` | List orders (optional `?user_id=`, `?status=`) |
| GET | `/api/orders/:id` | Get order with line items |
| POST | `/api/orders` | Create order |
| PATCH | `/api/orders/:id` | Update order status |
| POST | `/api/auth/signup` | Create user account |
| POST | `/api/auth/login` | Login, returns user |
| GET | `/api/auth/users` | List all users (no passwords) |

### Create product (POST /api/products)

```json
{
  "name": "Espresso",
  "sku": "SKU-006",
  "price": 2.50,
  "cost": 0.60,
  "stock": 50,
  "category_id": 1
}
```

### Create order (POST /api/orders)

```json
{
  "user_id": "optional-user-id",
  "items": [
    { "product_id": 1, "quantity": 2 },
    { "product_id": 3, "quantity": 1 }
  ]
}
```

### Update order status (PATCH /api/orders/:id)

```json
{ "status": "completed" }
```
`status`: `pending` | `completed` | `cancelled`

## Using from Flutter

Point your app to `http://localhost:3000` (or your deployed URL) for products and orders.
