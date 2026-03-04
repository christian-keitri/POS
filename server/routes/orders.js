const express = require('express');
const router = express.Router();
const db = require('../db');
const { safeErrorMessage } = require('../lib/safeError');

// GET all orders (optional ?user_id=, ?status=)
router.get('/', (req, res) => {
  try {
    const { user_id, status } = req.query;
    let sql = 'SELECT * FROM orders WHERE 1=1';
    const params = [];
    if (user_id) {
      sql += ' AND user_id = ?';
      params.push(user_id);
    }
    if (status) {
      sql += ' AND status = ?';
      params.push(status);
    }
    sql += ' ORDER BY created_at DESC';
    const orders = db.prepare(sql).all(...params);
    res.json(orders);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// GET stats (today's orders count and revenue) - must be before /:id
router.get('/stats', (req, res) => {
  try {
    const { user_id } = req.query;
    let sql = `
      SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as revenue
      FROM orders
      WHERE DATE(created_at) = DATE('now', 'localtime')
      AND status != 'cancelled'
    `;
    const params = [];
    if (user_id) {
      sql += ' AND user_id = ?';
      params.push(user_id);
    }
    const row = db.prepare(sql).get(...params);
    res.json({
      today_orders_count: row.count,
      today_revenue: row.revenue ?? 0,
    });
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// GET single order with items
router.get('/:id', (req, res) => {
  try {
    const order = db.prepare('SELECT * FROM orders WHERE id = ?').get(req.params.id);
    if (!order) return res.status(404).json({ error: 'Order not found' });
    const items = db.prepare(`
      SELECT oi.*, p.name as product_name
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      WHERE oi.order_id = ?
    `).all(req.params.id);
    res.json({ ...order, items });
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// POST create order (body: { user_id?, cashier_id?, payment_method?, notes?, items: [{ product_id, quantity }] })
router.post('/', (req, res) => {
  try {
    const { user_id, cashier_id, payment_method, notes, items } = req.body;
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'items array with product_id and quantity is required' });
    }

    const insertOrder = db.prepare(`
      INSERT INTO orders (user_id, cashier_id, total, status, payment_method, notes)
      VALUES (?, ?, 0, ?, ?, ?)
    `);
    const insertItem = db.prepare(`
      INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal)
      VALUES (?, ?, ?, ?, ?)
    `);
    const updateProductStock = db.prepare('UPDATE products SET stock = stock - ? WHERE id = ?');

    let total = 0;
    const productPrices = new Map(); // key: product id (number)

    for (const item of items) {
      const productId = Number(item.product_id);
      const qty = Math.max(1, Number(item.quantity) || 1);
      const product = db.prepare('SELECT id, name, price, stock FROM products WHERE id = ?').get(productId);
      if (!product) {
        return res.status(400).json({ error: `Product ${productId} not found` });
      }
      if (product.stock < qty) {
        return res.status(400).json({ error: `Insufficient stock for "${product.name}" (have ${product.stock}, need ${qty})` });
      }
      const subtotal = product.price * qty;
      total += subtotal;
      productPrices.set(productId, { price: product.price, quantity: qty });
    }

    const run = db.transaction(() => {
      const orderResult = insertOrder.run(
        user_id != null ? String(user_id) : null,
        cashier_id != null ? Number(cashier_id) : null,
        'pending',
        payment_method?.trim() || null,
        notes?.trim() || null
      );
      const orderId = Number(orderResult.lastInsertRowid);
      for (const item of items) {
        const productId = Number(item.product_id);
        const qty = productPrices.get(productId).quantity;
        const price = productPrices.get(productId).price;
        const subtotal = price * qty;
        insertItem.run(orderId, productId, qty, price, subtotal);
        updateProductStock.run(qty, productId);
      }
      db.prepare('UPDATE orders SET total = ? WHERE id = ?').run(total, orderId);
      return orderId;
    });

    const orderId = run();
    const order = db.prepare('SELECT * FROM orders WHERE id = ?').get(orderId);
    const orderItems = db.prepare(`
      SELECT oi.*, p.name as product_name
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      WHERE oi.order_id = ?
    `).all(orderId);
    res.status(201).json({ ...order, items: orderItems });
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// PATCH order (status, payment_method, notes)
router.patch('/:id', (req, res) => {
  try {
    const { status, payment_method, notes } = req.body;
    const id = req.params.id;
    const existing = db.prepare('SELECT * FROM orders WHERE id = ?').get(id);
    if (!existing) return res.status(404).json({ error: 'Order not found' });

    const updates = [];
    const params = [];
    if (status && ['pending', 'completed', 'cancelled'].includes(status)) {
      updates.push('status = ?');
      params.push(status);
    }
    if (payment_method !== undefined) {
      updates.push('payment_method = ?');
      params.push(payment_method?.trim() || null);
    }
    if (notes !== undefined) {
      updates.push('notes = ?');
      params.push(notes?.trim() || null);
    }
    if (updates.length === 0) {
      return res.status(400).json({ error: 'Provide at least one of: status, payment_method, notes' });
    }
    updates.push("updated_at = datetime('now')");
    params.push(id);
    const result = db.prepare(`UPDATE orders SET ${updates.join(', ')} WHERE id = ?`).run(...params);
    if (result.changes === 0) return res.status(404).json({ error: 'Order not found' });
    const order = db.prepare('SELECT * FROM orders WHERE id = ?').get(id);
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

module.exports = router;
