const express = require('express');
const router = express.Router();
const db = require('../db');

// GET all products (optional ?category_id=)
router.get('/', (req, res) => {
  try {
    const { category_id } = req.query;
    let sql = `
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
    `;
    const params = [];
    if (category_id) {
      sql += ' WHERE p.category_id = ?';
      params.push(category_id);
    }
    sql += ' ORDER BY p.name';
    const products = db.prepare(sql).all(...params);
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET single product
router.get('/:id', (req, res) => {
  try {
    const row = db.prepare(`
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = ?
    `).get(req.params.id);
    if (!row) return res.status(404).json({ error: 'Product not found' });
    res.json(row);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST create product
router.post('/', (req, res) => {
  try {
    const { name, sku, price, cost, stock, category_id } = req.body;
    if (!name || price == null) {
      return res.status(400).json({ error: 'name and price are required' });
    }
    const stmt = db.prepare(`
      INSERT INTO products (name, sku, price, cost, stock, category_id)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    const result = stmt.run(
      name,
      sku || null,
      Number(price),
      cost != null ? Number(cost) : 0,
      stock != null ? Number(stock) : 0,
      category_id || null
    );
    const product = db.prepare('SELECT * FROM products WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT update product
router.put('/:id', (req, res) => {
  try {
    const { name, sku, price, cost, stock, category_id } = req.body;
    const id = req.params.id;
    const existing = db.prepare('SELECT * FROM products WHERE id = ?').get(id);
    if (!existing) return res.status(404).json({ error: 'Product not found' });

    const updates = {
      name: name !== undefined ? name : existing.name,
      sku: sku !== undefined ? sku : existing.sku,
      price: price != null ? Number(price) : existing.price,
      cost: cost != null ? Number(cost) : existing.cost,
      stock: stock != null ? Number(stock) : existing.stock,
      category_id: category_id !== undefined ? category_id : existing.category_id,
    };

    db.prepare(`
      UPDATE products
      SET name = ?, sku = ?, price = ?, cost = ?, stock = ?, category_id = ?,
          updated_at = datetime('now')
      WHERE id = ?
    `).run(updates.name, updates.sku, updates.price, updates.cost, updates.stock, updates.category_id, id);

    const product = db.prepare('SELECT * FROM products WHERE id = ?').get(id);
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE product
router.delete('/:id', (req, res) => {
  try {
    const result = db.prepare('DELETE FROM products WHERE id = ?').run(req.params.id);
    if (result.changes === 0) return res.status(404).json({ error: 'Product not found' });
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
