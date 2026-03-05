const express = require('express');
const router = express.Router();
const db = require('../db');
const { safeErrorMessage } = require('../lib/safeError');

// Helper to generate unique order number
function generateOrderNumber() {
  const date = new Date();
  const year = date.getFullYear().toString().slice(-2);
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const random = Math.floor(Math.random() * 9999).toString().padStart(4, '0');
  return `ORD-${year}${month}${day}-${random}`;
}

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

// POST create order (body: { user_id?, cashier_id?, payment_method?, payment_details?, tax_rate?, discount_amount?, notes?, items: [{ product_id, quantity, discount? }] })
router.post('/', (req, res) => {
  try {
    const { user_id, cashier_id, payment_method, payment_details, tax_rate = 0, discount_amount = 0, notes, items } = req.body;
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'items array with product_id and quantity is required' });
    }

    const orderNumber = generateOrderNumber();
    const insertOrder = db.prepare(`
      INSERT INTO orders (order_number, user_id, cashier_id, subtotal, tax_amount, discount_amount, total, status, payment_method, payment_details, notes)
      VALUES (?, ?, ?, 0, 0, 0, 0, ?, ?, ?, ?)
    `);
    const insertItem = db.prepare(`
      INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, subtotal, discount_amount)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);
    const updateProductStock = db.prepare('UPDATE products SET stock = stock - ?, updated_at = datetime(\'now\') WHERE id = ?');
    const logStockAdjustment = db.prepare(`
      INSERT INTO stock_adjustments (product_id, user_id, quantity_change, old_stock, new_stock, reason, reference_type, reference_id)
      VALUES (?, ?, ?, ?, ?, 'sale', 'order', ?)
    `);

    let subtotal = 0;
    const productData = []; // Store product info for processing

    // Validate all products and calculate totals
    for (const item of items) {
      const productId = Number(item.product_id);
      const qty = Math.max(1, Number(item.quantity) || 1);
      const itemDiscount = Number(item.discount || 0);
      
      const product = db.prepare('SELECT id, name, price, stock FROM products WHERE id = ?').get(productId);
      if (!product) {
        return res.status(400).json({ error: `Product ${productId} not found` });
      }
      if (product.stock < qty) {
        return res.status(400).json({ error: `Insufficient stock for "${product.name}" (available: ${product.stock}, requested: ${qty})` });
      }
      
      const itemSubtotal = (product.price * qty) - itemDiscount;
      subtotal += itemSubtotal;
      
      productData.push({
        id: productId,
        name: product.name,
        price: product.price,
        quantity: qty,
        discount: itemDiscount,
        subtotal: itemSubtotal,
        oldStock: product.stock
      });
    }

    const taxAmount = subtotal * (tax_rate / 100);
    const totalDiscount = Number(discount_amount);
    const total = subtotal + taxAmount - totalDiscount;

    // Create order and update stock in a transaction
    const run = db.transaction(() => {
      const orderResult = insertOrder.run(
        orderNumber,
        user_id != null ? Number(user_id) : null,
        cashier_id != null ? Number(cashier_id) : null,
        'pending',
        payment_method?.trim() || null,
        payment_details ? JSON.stringify(payment_details) : null,
        notes?.trim() || null
      );
      const orderId = Number(orderResult.lastInsertRowid);
      
      // Insert order items and update stock
      for (const prod of productData) {
        insertItem.run(orderId, prod.id, prod.name, prod.quantity, prod.price, prod.subtotal, prod.discount);
        updateProductStock.run(prod.quantity, prod.id);
        
        // Log stock adjustment
        const newStock = prod.oldStock - prod.quantity;
        logStockAdjustment.run(prod.id, cashier_id || null, -prod.quantity, prod.oldStock, newStock, orderId);
      }
      
      // Update order totals
      db.prepare('UPDATE orders SET subtotal = ?, tax_amount = ?, discount_amount = ?, total = ? WHERE id = ?')
        .run(subtotal, taxAmount, totalDiscount, total, orderId);
      
      return orderId;
    });

    const orderId = run();
    const order = db.prepare('SELECT * FROM orders WHERE id = ?').get(orderId);
    const orderItems = db.prepare(`
      SELECT oi.*
      FROM order_items oi
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
    const { status, payment_method, payment_details, notes } = req.body;
    const id = req.params.id;
    const existing = db.prepare('SELECT * FROM orders WHERE id = ?').get(id);
    if (!existing) return res.status(404).json({ error: 'Order not found' });

    const updates = [];
    const params = [];
    
    const validStatuses = ['pending', 'completed', 'cancelled', 'refunded'];
    if (status && validStatuses.includes(status)) {
      updates.push('status = ?');
      params.push(status);
    }
    
    if (payment_method !== undefined) {
      updates.push('payment_method = ?');
      params.push(payment_method?.trim() || null);
    }
    
    if (payment_details !== undefined) {
      updates.push('payment_details = ?');
      params.push(payment_details ? JSON.stringify(payment_details) : null);
    }
    
    if (notes !== undefined) {
      updates.push('notes = ?');
      params.push(notes?.trim() || null);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({ error: 'Provide at least one field to update' });
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

// GET /api/orders/:id/receipt - Generate receipt data
router.get('/:id/receipt', (req, res) => {
  try {
    const order = db.prepare(`
      SELECT o.*, u.email as cashier_email, u.display_name as cashier_name, u.business_name
      FROM orders o
      LEFT JOIN users u ON o.cashier_id = u.id
      WHERE o.id = ?
    `).get(req.params.id);
    
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    const items = db.prepare(`
      SELECT oi.*
      FROM order_items oi
      WHERE oi.order_id = ?
    `).all(req.params.id);
    
    const receipt = {
      order_number: order.order_number,
      business_name: order.business_name || 'POS System',
      date: order.created_at,
      cashier: order.cashier_name || order.cashier_email || 'N/A',
      items: items.map(item => ({
        name: item.product_name,
        quantity: item.quantity,
        unit_price: item.unit_price,
        discount: item.discount_amount || 0,
        subtotal: item.subtotal
      })),
      subtotal: order.subtotal,
      tax_amount: order.tax_amount || 0,
      discount_amount: order.discount_amount || 0,
      total: order.total,
      payment_method: order.payment_method,
      status: order.status,
      notes: order.notes
    };
    
    res.json(receipt);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

module.exports = router;
