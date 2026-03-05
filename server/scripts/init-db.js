/**
 * Initializes the SQLite database with schema and optional seed data.
 * Run: node scripts/init-db.js
 */

const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const defaultDbPath = path.join(__dirname, '..', 'data', 'pos.db');
const dbPath = process.env.DB_PATH || defaultDbPath;
const dataDir = path.dirname(dbPath);
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });

const db = new Database(dbPath);

// Enable foreign keys
db.pragma('foreign_keys = ON');

// Schema
db.exec(`
  -- Users (for signup/login with role-based access)
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    business_name TEXT,
    display_name TEXT,
    role TEXT DEFAULT 'cashier' CHECK (role IN ('admin', 'manager', 'cashier')),
    is_active INTEGER DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );

  -- Categories for products
  CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );

  -- Products
  CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    sku TEXT UNIQUE,
    barcode TEXT,
    description TEXT,
    price REAL NOT NULL CHECK (price >= 0),
    cost REAL DEFAULT 0 CHECK (cost >= 0),
    stock INTEGER DEFAULT 0 CHECK (stock >= 0),
    low_stock_threshold INTEGER DEFAULT 10,
    category_id INTEGER REFERENCES categories(id),
    image_path TEXT,
    is_active INTEGER DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );

  -- Orders (enhanced with more payment details)
  CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_number TEXT UNIQUE,
    user_id INTEGER REFERENCES users(id),
    cashier_id INTEGER REFERENCES users(id),
    total REAL NOT NULL DEFAULT 0,
    subtotal REAL NOT NULL DEFAULT 0,
    tax_amount REAL DEFAULT 0,
    discount_amount REAL DEFAULT 0,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled', 'refunded')),
    payment_method TEXT CHECK (payment_method IN ('cash', 'card', 'digital_wallet', 'mixed')),
    payment_details TEXT,
    notes TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );

  -- Order line items (enhanced with discount)
  CREATE TABLE IF NOT EXISTS order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price REAL NOT NULL,
    subtotal REAL NOT NULL,
    discount_amount REAL DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now'))
  );

  -- Stock adjustments log
  CREATE TABLE IF NOT EXISTS stock_adjustments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL REFERENCES products(id),
    user_id INTEGER REFERENCES users(id),
    quantity_change INTEGER NOT NULL,
    old_stock INTEGER NOT NULL,
    new_stock INTEGER NOT NULL,
    reason TEXT CHECK (reason IN ('sale', 'purchase', 'adjustment', 'damage', 'return')),
    notes TEXT,
    reference_type TEXT,
    reference_id INTEGER,
    created_at TEXT DEFAULT (datetime('now'))
  );

  -- User activity logs for audit trail
  CREATE TABLE IF NOT EXISTS user_activity_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER REFERENCES users(id),
    action TEXT NOT NULL,
    entity_type TEXT,
    entity_id INTEGER,
    details TEXT,
    ip_address TEXT,
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
  CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
  CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
  CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
  CREATE INDEX IF NOT EXISTS idx_orders_cashier ON orders(cashier_id);
  CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at);
  CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
  CREATE INDEX IF NOT EXISTS idx_orders_number ON orders(order_number);
  CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
  CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);
  CREATE INDEX IF NOT EXISTS idx_stock_adj_product ON stock_adjustments(product_id);
  CREATE INDEX IF NOT EXISTS idx_stock_adj_created ON stock_adjustments(created_at);
  CREATE INDEX IF NOT EXISTS idx_activity_logs_user ON user_activity_logs(user_id);
  CREATE INDEX IF NOT EXISTS idx_activity_logs_created ON user_activity_logs(created_at);
`);

// Migrations: add new columns to existing DBs (safe to run multiple times)
function addColumnIfMissing(table, column, definition) {
  try {
    db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
  } catch (e) {
    if (!e.message.includes('duplicate column')) throw e;
  }
}

// User table migrations
addColumnIfMissing('users', 'updated_at', 'TEXT');
addColumnIfMissing('users', 'display_name', 'TEXT');
addColumnIfMissing('users', 'is_active', 'INTEGER DEFAULT 1');

// Category table migrations
addColumnIfMissing('categories', 'description', 'TEXT');
addColumnIfMissing('categories', 'sort_order', 'INTEGER DEFAULT 0');
addColumnIfMissing('categories', 'is_active', 'INTEGER DEFAULT 1');
addColumnIfMissing('categories', 'updated_at', 'TEXT');

// Product table migrations
addColumnIfMissing('products', 'image_path', 'TEXT');
addColumnIfMissing('products', 'barcode', 'TEXT');
addColumnIfMissing('products', 'description', 'TEXT');
addColumnIfMissing('products', 'is_active', 'INTEGER DEFAULT 1');
addColumnIfMissing('products', 'low_stock_threshold', 'INTEGER DEFAULT 10');

// Order table migrations
addColumnIfMissing('orders', 'cashier_id', 'INTEGER REFERENCES users(id)');
addColumnIfMissing('orders', 'payment_method', 'TEXT');
addColumnIfMissing('orders', 'notes', 'TEXT');
addColumnIfMissing('orders', 'updated_at', 'TEXT');
addColumnIfMissing('orders', 'order_number', 'TEXT');
addColumnIfMissing('orders', 'subtotal', 'REAL DEFAULT 0');
addColumnIfMissing('orders', 'tax_amount', 'REAL DEFAULT 0');
addColumnIfMissing('orders', 'discount_amount', 'REAL DEFAULT 0');
addColumnIfMissing('orders', 'payment_details', 'TEXT');

// Order items migrations
addColumnIfMissing('order_items', 'product_name', 'TEXT');
addColumnIfMissing('order_items', 'discount_amount', 'REAL DEFAULT 0');

// Backfill new datetime columns (SQLite ALTER doesn't allow datetime('now'))
db.exec(`UPDATE users SET updated_at = datetime('now') WHERE updated_at IS NULL OR updated_at = ''`);
db.exec(`UPDATE orders SET updated_at = created_at WHERE updated_at IS NULL OR updated_at = ''`);
db.exec(`UPDATE categories SET updated_at = datetime('now') WHERE updated_at IS NULL OR updated_at = ''`);

// Backfill order_number for existing orders
db.exec(`UPDATE orders SET order_number = 'ORD-' || printf('%06d', id) WHERE order_number IS NULL`);

// Backfill subtotal for existing orders
db.exec(`UPDATE orders SET subtotal = total WHERE subtotal = 0 OR subtotal IS NULL`);

// Backfill product_name for existing order_items
db.exec(`
  UPDATE order_items 
  SET product_name = (SELECT name FROM products WHERE products.id = order_items.product_id)
  WHERE product_name IS NULL OR product_name = ''
`);

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
