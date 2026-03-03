/**
 * Initializes the SQLite database with schema and optional seed data.
 * Run: node scripts/init-db.js
 */

const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
const dbPath = path.join(dataDir, 'pos.db');

const db = new Database(dbPath);

// Enable foreign keys
db.pragma('foreign_keys = ON');

// Schema
db.exec(`
  -- Users (for signup/login)
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    business_name TEXT,
    role TEXT DEFAULT 'admin',
    created_at TEXT DEFAULT (datetime('now'))
  );

  -- Categories for products
  CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    created_at TEXT DEFAULT (datetime('now'))
  );

  -- Products
  CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    sku TEXT UNIQUE,
    price REAL NOT NULL CHECK (price >= 0),
    cost REAL DEFAULT 0 CHECK (cost >= 0),
    stock INTEGER DEFAULT 0 CHECK (stock >= 0),
    category_id INTEGER REFERENCES categories(id),
    image_path TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );

  -- Orders (optional user_id from your app)
  CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT,
    total REAL NOT NULL DEFAULT 0,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled')),
    created_at TEXT DEFAULT (datetime('now'))
  );

  -- Order line items
  CREATE TABLE IF NOT EXISTS order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price REAL NOT NULL,
    subtotal REAL NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
  CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
  CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at);
  CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
`);

// Add image_path to products if missing (for existing DBs)
try {
  db.exec(`ALTER TABLE products ADD COLUMN image_path TEXT`);
} catch (e) {
  if (!e.message.includes('duplicate column')) throw e;
}

// Seed data (only if tables are empty)
const categoryCount = db.prepare('SELECT COUNT(*) as c FROM categories').get();
if (categoryCount.c === 0) {
  const insertCategory = db.prepare('INSERT INTO categories (name) VALUES (?)');
  insertCategory.run('Beverages');
  insertCategory.run('Snacks');
  insertCategory.run('Dairy');
  insertCategory.run('General');
}

const productCount = db.prepare('SELECT COUNT(*) as c FROM products').get();
if (productCount.c === 0) {
  const insertProduct = db.prepare(
    'INSERT INTO products (name, sku, price, cost, stock, category_id) VALUES (?, ?, ?, ?, ?, ?)'
  );
  insertProduct.run('Coffee', 'SKU-001', 3.50, 1.00, 100, 1);
  insertProduct.run('Tea', 'SKU-002', 2.50, 0.50, 80, 1);
  insertProduct.run('Chips', 'SKU-003', 2.00, 0.80, 50, 2);
  insertProduct.run('Milk', 'SKU-004', 2.99, 1.20, 40, 3);
  insertProduct.run('Water', 'SKU-005', 1.50, 0.30, 200, 1);
}

db.close();
console.log('Database initialized at', dbPath);
