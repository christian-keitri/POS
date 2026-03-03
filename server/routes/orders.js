const express = require('express');
const router = express.Router();
const db = require('../db');

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
    res.status(500).json({ error: err.message });
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
    res.status(500).json({ error: err.message });
  }
});

// POST create order (body: { user_id?, items: [{ product_id, quantity }] })
router.post('/', (req, res) => {
  try {
    const { user_id, items } = req.body;
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'items array with product_id and quantity is required' });
    }

    const insertOrder = db.prepare('INSERT INTO orders (user_id, total, status) VALUES (?, 0, ?)');
    const insertItem = db.prepare(`
      INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal)
      VALUES (?, ?, ?, ?, ?)
    `);
    const updateProductStock = db.prepare('UPDATE products SET stock = stock - ? WHERE id = ?');

    let total = 0;
    const productPrices = new Map();

    for (const item of items) {
      const { product_id, quantity } = item;
      const qty = Number(quantity) || 1;
      const product = db.prepare('SELECT id, price, stock FROM products WHERE id = ?').get(product_id);
      if (!product) {
        return res.status(400).json({ error: `Product ${product_id} not found` });
      }
      if (product.stock < qty) {
        return res.status(400).json({ error: `Insufficient stock for product ${product.name}` });
      }
      const subtotal = product.price * qty;
      total += subtotal;
      productPrices.set(product_id, { price: product.price, quantity: qty });
    }

    const run = db.transaction(() => {
      const orderResult = insertOrder.run(user_id || null, 'pending');
      const orderId = orderResult.lastInsertRowid;
      for (const item of items) {
        const { product_id, quantity } = item;
        const qty = Number(quantity) || 1;
        const { price } = productPrices.get(product_id);
        const subtotal = price * qty;
        insertItem.run(orderId, product_id, qty, price, subtotal);
        updateProductStock.run(qty, product_id);
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
    res.status(500).json({ error: err.message });
  }
});

// PATCH order status (e.g. complete or cancel)
router.patch('/:id', (req, res) => {
  try {
    const { status } = req.body;
    if (!status || !['pending', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ error: 'status must be pending, completed, or cancelled' });
    }
    const result = db.prepare('UPDATE orders SET status = ? WHERE id = ?').run(status, req.params.id);
    if (result.changes === 0) return res.status(404).json({ error: 'Order not found' });
    const order = db.prepare('SELECT * FROM orders WHERE id = ?').get(req.params.id);
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
