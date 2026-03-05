const express = require('express');
const router = express.Router();
const db = require('../db');
const { safeErrorMessage } = require('../lib/safeError');

// GET /api/stock/adjustments - List stock adjustment logs
router.get('/adjustments', (req, res) => {
  try {
    const { product_id, user_id, reason, limit = 100, offset = 0 } = req.query;
    let sql = `
      SELECT 
        sa.*,
        p.name as product_name,
        p.sku as product_sku,
        u.email as user_email,
        u.display_name as user_name
      FROM stock_adjustments sa
      LEFT JOIN products p ON sa.product_id = p.id
      LEFT JOIN users u ON sa.user_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (product_id) {
      sql += ' AND sa.product_id = ?';
      params.push(product_id);
    }
    if (user_id) {
      sql += ' AND sa.user_id = ?';
      params.push(user_id);
    }
    if (reason) {
      sql += ' AND sa.reason = ?';
      params.push(reason);
    }

    sql += ' ORDER BY sa.created_at DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));

    const adjustments = db.prepare(sql).all(...params);
    res.json(adjustments);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// POST /api/stock/adjust - Manual stock adjustment
router.post('/adjust', (req, res) => {
  try {
    const { product_id, user_id, quantity_change, reason, notes } = req.body;

    if (!product_id || quantity_change == null) {
      return res.status(400).json({ error: 'product_id and quantity_change are required' });
    }

    const validReasons = ['purchase', 'adjustment', 'damage', 'return'];
    if (reason && !validReasons.includes(reason)) {
      return res.status(400).json({ error: 'Invalid reason. Must be: purchase, adjustment, damage, or return' });
    }

    const product = db.prepare('SELECT id, name, stock FROM products WHERE id = ?').get(product_id);
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const quantityChange = Number(quantity_change);
    const oldStock = product.stock;
    const newStock = oldStock + quantityChange;

    if (newStock < 0) {
      return res.status(400).json({ error: `Insufficient stock. Current: ${oldStock}, Change: ${quantityChange}` });
    }

    // Use transaction for consistency
    const adjust = db.transaction(() => {
      // Update product stock
      db.prepare('UPDATE products SET stock = ?, updated_at = datetime(\'now\') WHERE id = ?').run(newStock, product_id);

      // Log the adjustment
      const result = db.prepare(`
        INSERT INTO stock_adjustments (product_id, user_id, quantity_change, old_stock, new_stock, reason, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(
        product_id,
        user_id || null,
        quantityChange,
        oldStock,
        newStock,
        reason || 'adjustment',
        notes || null
      );

      return result.lastInsertRowid;
    });

    const adjustmentId = adjust();
    const adjustment = db.prepare(`
      SELECT sa.*, p.name as product_name, p.sku as product_sku
      FROM stock_adjustments sa
      LEFT JOIN products p ON sa.product_id = p.id
      WHERE sa.id = ?
    `).get(adjustmentId);

    res.status(201).json(adjustment);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// GET /api/stock/alerts - Get low stock alerts
router.get('/alerts', (req, res) => {
  try {
    const { category_id } = req.query;
    let sql = `
      SELECT 
        p.*,
        c.name as category_name,
        (p.low_stock_threshold - p.stock) as units_needed
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.is_active = 1 
      AND p.stock <= p.low_stock_threshold
    `;
    const params = [];

    if (category_id) {
      sql += ' AND p.category_id = ?';
      params.push(category_id);
    }

    sql += ' ORDER BY (p.stock / NULLIF(p.low_stock_threshold, 0)) ASC, p.stock ASC';

    const alerts = db.prepare(sql).all(...params);
    res.json(alerts);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// Helper function to log stock changes from orders
function logOrderStockChange(orderId, userId = null) {
  const orderItems = db.prepare(`
    SELECT oi.product_id, oi.quantity, p.name, p.stock
    FROM order_items oi
    JOIN products p ON oi.product_id = p.id
    WHERE oi.order_id = ?
  `).all(orderId);

  const insertLog = db.prepare(`
    INSERT INTO stock_adjustments (product_id, user_id, quantity_change, old_stock, new_stock, reason, reference_type, reference_id)
    VALUES (?, ?, ?, ?, ?, 'sale', 'order', ?)
  `);

  for (const item of orderItems) {
    const oldStock = item.stock + item.quantity; // Calculate what it was before the sale
    const newStock = item.stock;
    insertLog.run(item.product_id, userId, -item.quantity, oldStock, newStock, orderId);
  }
}

module.exports = router;
module.exports.logOrderStockChange = logOrderStockChange;
