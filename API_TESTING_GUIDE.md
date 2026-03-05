# POS API Testing Guide

## Quick API Test Examples

All examples assume the server is running at `http://localhost:3000`

---

## 🔐 Authentication

### Signup (Create Admin Account)
```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com",
    "password": "admin123",
    "business_name": "My Store",
    "display_name": "Admin User"
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com",
    "password": "admin123"
  }'
```

### List All Users
```bash
curl http://localhost:3000/api/auth/users
```

### Create Cashier
```bash
curl -X POST http://localhost:3000/api/auth/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "cashier@test.com",
    "password": "cashier123",
    "display_name": "Cashier User",
    "role": "cashier"
  }'
```

---

## 📦 Products

### List All Products
```bash
curl http://localhost:3000/api/products
```

### Get Products by Category
```bash
curl "http://localhost:3000/api/products?category_id=1"
```

### Get Active Products Only
```bash
curl "http://localhost:3000/api/products?active_only=1"
```

### Get Single Product
```bash
curl http://localhost:3000/api/products/1
```

### Create Product
```bash
curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Latte",
    "sku": "SKU-006",
    "barcode": "123456789",
    "description": "Premium coffee latte",
    "price": 4.50,
    "cost": 2.00,
    "stock": 50,
    "low_stock_threshold": 15,
    "category_id": 1,
    "is_active": true
  }'
```

### Update Product
```bash
curl -X PUT http://localhost:3000/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "price": 3.99,
    "stock": 120
  }'
```

### Upload Product Image
```bash
curl -X POST http://localhost:3000/api/products/1/image \
  -F "image=@/path/to/image.jpg"
```

---

## 📂 Categories

### List Categories
```bash
curl http://localhost:3000/api/categories
```

### Create Category
```bash
curl -X POST http://localhost:3000/api/categories \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Hot Drinks",
    "description": "Coffee, tea, and other hot beverages",
    "sort_order": 1
  }'
```

### Update Category
```bash
curl -X PUT http://localhost:3000/api/categories/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Hot Beverages",
    "sort_order": 1
  }'
```

---

## 💰 Orders

### Create Order
```bash
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "cashier_id": 1,
    "payment_method": "cash",
    "tax_rate": 10,
    "discount_amount": 0,
    "notes": "Customer paid exact change",
    "items": [
      {
        "product_id": 1,
        "quantity": 2,
        "discount": 0
      },
      {
        "product_id": 2,
        "quantity": 1,
        "discount": 0
      }
    ]
  }'
```

### List All Orders
```bash
curl http://localhost:3000/api/orders
```

### Get Completed Orders Only
```bash
curl "http://localhost:3000/api/orders?status=completed"
```

### Get Order Details with Items
```bash
curl http://localhost:3000/api/orders/1
```

### Update Order Status
```bash
curl -X PATCH http://localhost:3000/api/orders/1 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed",
    "payment_method": "card"
  }'
```

### Get Receipt Data
```bash
curl http://localhost:3000/api/orders/1/receipt
```

### Get Order Statistics
```bash
curl http://localhost:3000/api/orders/stats
```

---

## 📊 Stock Management

### Get Stock Adjustments
```bash
curl http://localhost:3000/api/stock/adjustments
```

### Get Adjustments for Specific Product
```bash
curl "http://localhost:3000/api/stock/adjustments?product_id=1"
```

### Manual Stock Adjustment
```bash
curl -X POST http://localhost:3000/api/stock/adjust \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 1,
    "user_id": 1,
    "quantity_change": 50,
    "reason": "purchase",
    "notes": "Restocking from supplier ABC"
  }'
```

### Reduce Stock (Damage/Loss)
```bash
curl -X POST http://localhost:3000/api/stock/adjust \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 1,
    "user_id": 1,
    "quantity_change": -5,
    "reason": "damage",
    "notes": "Damaged during delivery"
  }'
```

### Get Low Stock Alerts
```bash
curl http://localhost:3000/api/stock/alerts
```

---

## 📈 Reports

### Sales Report (Today)
```bash
curl "http://localhost:3000/api/reports/sales?period=daily"
```

### Sales Report (This Week)
```bash
curl "http://localhost:3000/api/reports/sales?period=weekly"
```

### Sales Report (This Month)
```bash
curl "http://localhost:3000/api/reports/sales?period=monthly"
```

### Sales Report (Custom Date Range)
```bash
curl "http://localhost:3000/api/reports/sales?start_date=2026-03-01&end_date=2026-03-05"
```

### Sales Report by Cashier
```bash
curl "http://localhost:3000/api/reports/sales?cashier_id=1&period=monthly"
```

### Inventory Report
```bash
curl http://localhost:3000/api/reports/inventory
```

### Inventory Report by Category
```bash
curl "http://localhost:3000/api/reports/inventory?category_id=1"
```

### Low Stock Items Only
```bash
curl "http://localhost:3000/api/reports/inventory?low_stock_only=1"
```

### Top 10 Products (This Month)
```bash
curl "http://localhost:3000/api/reports/top-products?period=monthly&limit=10"
```

### Top Products (Custom Date Range)
```bash
curl "http://localhost:3000/api/reports/top-products?start_date=2026-03-01&end_date=2026-03-05&limit=20"
```

### Revenue Analytics (Last 30 Days)
```bash
curl "http://localhost:3000/api/reports/revenue?period=daily&days=30"
```

### Revenue Analytics (Weekly, Last 90 Days)
```bash
curl "http://localhost:3000/api/reports/revenue?period=weekly&days=90"
```

### User Activity Logs
```bash
curl http://localhost:3000/api/reports/user-activity
```

### Activity for Specific User
```bash
curl "http://localhost:3000/api/reports/user-activity?user_id=1&limit=50"
```

### Cashier Performance
```bash
curl "http://localhost:3000/api/reports/cashier-performance?period=monthly"
```

---

## 🧪 Complete Test Flow

### 1. Setup
```bash
# Create admin account
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"admin123","business_name":"Test Store"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"admin123"}'
```

### 2. Add Products
```bash
# Create category
curl -X POST http://localhost:3000/api/categories \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Category"}'

# Create product
curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","price":9.99,"cost":5.00,"stock":100,"category_id":1}'
```

### 3. Process Sale
```bash
# Create order
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "cashier_id": 1,
    "payment_method": "cash",
    "items": [{"product_id": 1, "quantity": 2}]
  }'

# Complete order
curl -X PATCH http://localhost:3000/api/orders/1 \
  -H "Content-Type: application/json" \
  -d '{"status":"completed"}'
```

### 4. Check Reports
```bash
# View sales report
curl "http://localhost:3000/api/reports/sales?period=daily"

# Check inventory
curl http://localhost:3000/api/reports/inventory

# View top products
curl "http://localhost:3000/api/reports/top-products?limit=5"
```

---

## 🔍 Testing Tips

### Pretty Print JSON Output
```bash
curl http://localhost:3000/api/products | jq
```

### Save Response to File
```bash
curl http://localhost:3000/api/reports/sales?period=monthly > sales-report.json
```

### Check Response Status
```bash
curl -w "\nHTTP Status: %{http_code}\n" http://localhost:3000/api/health
```

### Verbose Output (See Headers)
```bash
curl -v http://localhost:3000/api/products
```

---

## 📝 Response Examples

### Successful Product Creation
```json
{
  "id": 6,
  "name": "Latte",
  "sku": "SKU-006",
  "barcode": "123456789",
  "description": "Premium coffee latte",
  "price": 4.5,
  "cost": 2,
  "stock": 50,
  "low_stock_threshold": 15,
  "category_id": 1,
  "category_name": "Beverages",
  "image_path": null,
  "is_active": 1,
  "created_at": "2026-03-05 12:00:00",
  "updated_at": "2026-03-05 12:00:00"
}
```

### Sales Report Response
```json
{
  "summary": {
    "total_orders": 15,
    "total_revenue": 523.50,
    "average_order_value": 34.90,
    "total_subtotal": 475.91,
    "total_tax": 47.59,
    "total_discounts": 0
  },
  "daily_breakdown": [
    {
      "date": "2026-03-05",
      "orders_count": 8,
      "revenue": 287.20
    },
    {
      "date": "2026-03-04",
      "orders_count": 7,
      "revenue": 236.30
    }
  ],
  "payment_methods": [
    {
      "payment_method": "cash",
      "count": 8,
      "total": 312.40
    },
    {
      "payment_method": "card",
      "count": 7,
      "total": 211.10
    }
  ]
}
```

### Low Stock Alert Response
```json
[
  {
    "id": 4,
    "name": "Milk",
    "stock": 8,
    "low_stock_threshold": 10,
    "units_needed": 2,
    "category_name": "Dairy",
    "price": 2.99
  }
]
```

---

## ⚡ Quick Health Check Script

Save as `test-api.sh`:
```bash
#!/bin/bash

BASE_URL="http://localhost:3000"

echo "Testing POS API..."
echo "==================="

echo -n "Health Check: "
curl -s "$BASE_URL/api/health" | grep -q "ok" && echo "✅ PASS" || echo "❌ FAIL"

echo -n "Products Endpoint: "
curl -s "$BASE_URL/api/products" | grep -q "\\[" && echo "✅ PASS" || echo "❌ FAIL"

echo -n "Categories Endpoint: "
curl -s "$BASE_URL/api/categories" | grep -q "\\[" && echo "✅ PASS" || echo "❌ FAIL"

echo -n "Orders Endpoint: "
curl -s "$BASE_URL/api/orders" | grep -q "\\[" && echo "✅ PASS" || echo "❌ FAIL"

echo -n "Stock Alerts: "
curl -s "$BASE_URL/api/stock/alerts" | grep -q "\\[" && echo "✅ PASS" || echo "❌ FAIL"

echo "==================="
echo "All tests complete!"
```

Run with:
```bash
chmod +x test-api.sh
./test-api.sh
```

---

## 🎯 Postman Collection

Import this into Postman for easy testing:

1. Open Postman
2. Import → Link
3. Use: `https://www.postman.com/collections/create`
4. Create collection with all endpoints above

---

## 📌 Notes

- Replace `localhost:3000` with your server URL in production
- All timestamps are in SQLite datetime format
- IDs are auto-incrementing integers
- Prices are stored as floating-point numbers
- Stock quantities are integers
- All endpoints return JSON
- Error responses include an `error` field with message

---

**API is ready for testing!** 🚀
