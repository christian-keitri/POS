/**
 * Removes all orders and their line items from the database.
 * Run: node scripts/clear-orders.js
 */

const path = require('path');
const fs = require('fs');
const Database = require('better-sqlite3');

const dataDir = path.join(__dirname, '..', 'data');
const dbPath = path.join(dataDir, 'pos.db');

if (!fs.existsSync(dbPath)) {
  console.error('Database not found at', dbPath);
  process.exit(1);
}

const db = new Database(dbPath);
db.pragma('foreign_keys = ON');

const itemsDeleted = db.prepare('DELETE FROM order_items').run();
const ordersDeleted = db.prepare('DELETE FROM orders').run();

db.close();

console.log('Deleted', ordersDeleted.changes, 'orders and', itemsDeleted.changes, 'order items.');
console.log('Orders table is now empty.');
