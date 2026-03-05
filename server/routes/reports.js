const express = require('express');
const router = express.Router();
const db = require('../db');
const { safeErrorMessage } = require('../lib/safeError');

// GET /api/reports/sales - Sales reports with date range
router.get('/sales', (req, res) => {
  try {
    const { period = 'daily', start_date, end_date, cashier_id, status = 'completed' } = req.query;
    
    let dateFilter = '';
    const params = [];

    if (start_date && end_date) {
      dateFilter = 'AND DATE(o.created_at) BETWEEN ? AND ?';
      params.push(start_date, end_date);
    } else if (period === 'daily') {
      dateFilter = "AND DATE(o.created_at) = DATE('now', 'localtime')";
    } else if (period === 'weekly') {
      dateFilter = "AND DATE(o.created_at) >= DATE('now', 'localtime', '-7 days')";
    } else if (period === 'monthly') {
      dateFilter = "AND DATE(o.created_at) >= DATE('now', 'localtime', 'start of month')";
    }

    let cashierFilter = '';
    if (cashier_id) {
      cashierFilter = 'AND o.cashier_id = ?';
      params.push(cashier_id);
    }

    // Summary statistics
    const summarySQL = `
      SELECT 
        COUNT(*) as total_orders,
        COALESCE(SUM(o.total), 0) as total_revenue,
        COALESCE(AVG(o.total), 0) as average_order_value,
        COALESCE(SUM(o.subtotal), 0) as total_subtotal,
        COALESCE(SUM(o.tax_amount), 0) as total_tax,
        COALESCE(SUM(o.discount_amount), 0) as total_discounts
      FROM orders o
      WHERE o.status = ?
      ${dateFilter}
      ${cashierFilter}
    `;
    params.unshift(status);
    const summary = db.prepare(summarySQL).get(...params);

    // Daily breakdown
    const dailySQL = `
      SELECT 
        DATE(o.created_at) as date,
        COUNT(*) as orders_count,
        COALESCE(SUM(o.total), 0) as revenue
      FROM orders o
      WHERE o.status = ?
      ${dateFilter}
      ${cashierFilter}
      GROUP BY DATE(o.created_at)
      ORDER BY date DESC
    `;
    params[0] = status; // Reset first param
    const daily = db.prepare(dailySQL).all(...params);

    // Payment method breakdown
    const paymentSQL = `
      SELECT 
        o.payment_method,
        COUNT(*) as count,
        COALESCE(SUM(o.total), 0) as total
      FROM orders o
      WHERE o.status = ?
      ${dateFilter}
      ${cashierFilter}
      GROUP BY o.payment_method
      ORDER BY total DESC
    `;
    params[0] = status;
    const paymentMethods = db.prepare(paymentSQL).all(...params);

    res.json({
      summary,
      daily_breakdown: daily,
      payment_methods: paymentMethods,
      filters: { period, start_date, end_date, cashier_id, status }
    });
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// GET /api/reports/inventory - Inventory report
router.get('/inventory', (req, res) => {
  try {
    const { category_id, low_stock_only } = req.query;
    
    let sql = `
      SELECT 
        p.*,
        c.name as category_name,
        (p.stock * p.price) as stock_value,
        (p.stock * p.cost) as stock_cost_value,
        ((p.price - p.cost) * p.stock) as potential_profit
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.is_active = 1
    `;
    const params = [];

    if (category_id) {
      sql += ' AND p.category_id = ?';
      params.push(category_id);
    }

    if (low_stock_only === '1' || low_stock_only === 'true') {
      sql += ' AND p.stock <= p.low_stock_threshold';
    }

    sql += ' ORDER BY stock_value DESC';

    const products = db.prepare(sql).all(...params);

    // Summary statistics
    const summary = {
      total_products: products.length,
      total_stock_value: products.reduce((sum, p) => sum + (p.stock_value || 0), 0),
      total_stock_cost: products.reduce((sum, p) => sum + (p.stock_cost_value || 0), 0),
      potential_profit: products.reduce((sum, p) => sum + (p.potential_profit || 0), 0),
      low_stock_count: products.filter(p => p.stock <= p.low_stock_threshold).length
    };

    res.json({
      summary,
      products
    });
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// GET /api/reports/top-products - Best selling products
router.get('/top-products', (req, res) => {
  try {
    const { period = 'monthly', limit = 10, start_date, end_date } = req.query;
    
    let dateFilter = '';
    const params = [];

    if (start_date && end_date) {
      dateFilter = 'AND DATE(o.created_at) BETWEEN ? AND ?';
      params.push(start_date, end_date);
    } else if (period === 'daily') {
      dateFilter = "AND DATE(o.created_at) = DATE('now', 'localtime')";
    } else if (period === 'weekly') {
      dateFilter = "AND DATE(o.created_at) >= DATE('now', 'localtime', '-7 days')";
    } else if (period === 'monthly') {
      dateFilter = "AND DATE(o.created_at) >= DATE('now', 'localtime', 'start of month')";
    }

    const sql = `
      SELECT 
        p.id,
        p.name,
        p.sku,
        p.price,
        c.name as category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.subtotal) as total_revenue,
        COUNT(DISTINCT oi.order_id) as number_of_orders
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      LEFT JOIN categories c ON p.category_id = c.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.status = 'completed'
      ${dateFilter}
      GROUP BY p.id
      ORDER BY total_quantity_sold DESC
      LIMIT ?
    `;
    params.push(Number(limit));

    const topProducts = db.prepare(sql).all(...params);
    res.json(topProducts);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// GET /api/reports/user-activity - User activity logs
router.get('/user-activity', (req, res) => {
  try {
    const { user_id, action, start_date, end_date, limit = 100, offset = 0 } = req.query;
    
    let sql = `
      SELECT 
        ual.*,
        u.email as user_email,
        u.display_name as user_name,
        u.role as user_role
      FROM user_activity_logs ual
      LEFT JOIN users u ON ual.user_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (user_id) {
      sql += ' AND ual.user_id = ?';
      params.push(user_id);
    }

    if (action) {
      sql += ' AND ual.action = ?';
      params.push(action);
    }

    if (start_date && end_date) {
      sql += ' AND DATE(ual.created_at) BETWEEN ? AND ?';
      params.push(start_date, end_date);
    }

    sql += ' ORDER BY ual.created_at DESC LIMIT ? OFFSET ?';
    params.push(Number(limit), Number(offset));

    const logs = db.prepare(sql).all(...params);
    res.json(logs);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// GET /api/reports/revenue - Revenue analytics with trends
router.get('/revenue', (req, res) => {
  try {
    const { period = 'daily', days = 30 } = req.query;
    
    let groupBy = 'DATE(o.created_at)';
    let dateRange = `DATE('now', 'localtime', '-${days} days')`;

    if (period === 'weekly') {
      groupBy = "strftime('%Y-W%W', o.created_at)";
    } else if (period === 'monthly') {
      groupBy = "strftime('%Y-%m', o.created_at)";
    }

    const sql = `
      SELECT 
        ${groupBy} as period,
        COUNT(*) as orders_count,
        COALESCE(SUM(o.total), 0) as revenue,
        COALESCE(AVG(o.total), 0) as avg_order_value,
        COALESCE(SUM(o.subtotal), 0) as subtotal,
        COALESCE(SUM(o.tax_amount), 0) as tax,
        COALESCE(SUM(o.discount_amount), 0) as discounts
      FROM orders o
      WHERE o.status = 'completed'
      AND DATE(o.created_at) >= ${dateRange}
      GROUP BY ${groupBy}
      ORDER BY period DESC
    `;

    const revenue = db.prepare(sql).all();
    
    // Calculate totals
    const totals = {
      total_revenue: revenue.reduce((sum, r) => sum + r.revenue, 0),
      total_orders: revenue.reduce((sum, r) => sum + r.orders_count, 0),
      average_order_value: revenue.length > 0 
        ? revenue.reduce((sum, r) => sum + r.avg_order_value, 0) / revenue.length 
        : 0,
      total_discounts: revenue.reduce((sum, r) => sum + r.discounts, 0)
    };

    res.json({
      data: revenue,
      totals,
      filters: { period, days }
    });
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// GET /api/reports/cashier-performance - Cashier performance metrics
router.get('/cashier-performance', (req, res) => {
  try {
    const { start_date, end_date, period = 'monthly' } = req.query;
    
    let dateFilter = '';
    const params = [];

    if (start_date && end_date) {
      dateFilter = 'AND DATE(o.created_at) BETWEEN ? AND ?';
      params.push(start_date, end_date);
    } else if (period === 'daily') {
      dateFilter = "AND DATE(o.created_at) = DATE('now', 'localtime')";
    } else if (period === 'weekly') {
      dateFilter = "AND DATE(o.created_at) >= DATE('now', 'localtime', '-7 days')";
    } else if (period === 'monthly') {
      dateFilter = "AND DATE(o.created_at) >= DATE('now', 'localtime', 'start of month')";
    }

    const sql = `
      SELECT 
        u.id,
        u.email,
        u.display_name,
        u.role,
        COUNT(o.id) as total_orders,
        COALESCE(SUM(o.total), 0) as total_sales,
        COALESCE(AVG(o.total), 0) as avg_order_value,
        COUNT(DISTINCT DATE(o.created_at)) as active_days
      FROM users u
      LEFT JOIN orders o ON u.id = o.cashier_id AND o.status = 'completed' ${dateFilter}
      WHERE u.is_active = 1
      GROUP BY u.id
      ORDER BY total_sales DESC
    `;

    const performance = db.prepare(sql).all(...params);
    res.json(performance);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// Helper function to log user activity
function logUserActivity(userId, action, entityType = null, entityId = null, details = null, ipAddress = null) {
  try {
    db.prepare(`
      INSERT INTO user_activity_logs (user_id, action, entity_type, entity_id, details, ip_address)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(userId, action, entityType, entityId, details, ipAddress);
  } catch (err) {
    console.error('Failed to log user activity:', err);
  }
}

module.exports = router;
module.exports.logUserActivity = logUserActivity;
