const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const router = express.Router();
const db = require('../db');

const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsDir),
  filename: (_req, file, cb) => {
    const ext = (path.extname(file.originalname) || '.jpg').toLowerCase().replace(/[^a-z]/g, '') || 'jpg';
    cb(null, `product_${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok =
      /^image\/(jpeg|jpg|png|gif|webp)$/i.test(file.mimetype) ||
      file.mimetype === 'application/octet-stream' ||
      !file.mimetype;
    cb(null, !!ok);
  },
});

// GET all products (optional ?category_id=, ?active_only=1)
router.get('/', (req, res) => {
  try {
    const { category_id, active_only } = req.query;
    let sql = `
      SELECT p.*, c.name as category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
    `;
    const params = [];
    const conditions = [];
    if (category_id) {
      conditions.push('p.category_id = ?');
      params.push(category_id);
    }
    if (active_only === '1' || active_only === 'true') {
      conditions.push('(p.is_active = 1 OR p.is_active IS NULL)');
    }
    if (conditions.length) sql += ' WHERE ' + conditions.join(' AND ');
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
    const { name, sku, barcode, description, price, cost, stock, category_id, is_active } = req.body;
    if (!name || price == null) {
      return res.status(400).json({ error: 'name and price are required' });
    }
    const stmt = db.prepare(`
      INSERT INTO products (name, sku, barcode, description, price, cost, stock, category_id, image_path, is_active)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    const result = stmt.run(
      name,
      sku || null,
      barcode?.trim() || null,
      description?.trim() || null,
      Number(price),
      cost != null ? Number(cost) : 0,
      stock != null ? Number(stock) : 0,
      category_id || null,
      null,
      is_active !== undefined && is_active !== null ? (is_active ? 1 : 0) : 1
    );
    const product = db.prepare('SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON p.category_id = c.id WHERE p.id = ?').get(result.lastInsertRowid);
    res.status(201).json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST upload product image (multipart form with field "image")
router.post('/:id/image', upload.single('image'), (req, res) => {
  try {
    const id = req.params.id;
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }
    const existing = db.prepare('SELECT id, image_path FROM products WHERE id = ?').get(id);
    if (!existing) {
      fs.unlink(req.file.path, () => {});
      return res.status(404).json({ error: 'Product not found' });
    }
    if (existing.image_path) {
      const oldPath = path.join(uploadsDir, existing.image_path);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }
    const imagePath = path.basename(req.file.path);
    db.prepare('UPDATE products SET image_path = ?, updated_at = datetime(\'now\') WHERE id = ?').run(imagePath, id);
    const product = db.prepare('SELECT * FROM products WHERE id = ?').get(id);
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT update product
router.put('/:id', (req, res) => {
  try {
    const { name, sku, barcode, description, price, cost, stock, category_id, is_active } = req.body;
    const id = req.params.id;
    const existing = db.prepare('SELECT * FROM products WHERE id = ?').get(id);
    if (!existing) return res.status(404).json({ error: 'Product not found' });

    const updates = {
      name: name !== undefined ? name : existing.name,
      sku: sku !== undefined ? sku : existing.sku,
      barcode: barcode !== undefined ? (barcode?.trim() || null) : existing.barcode,
      description: description !== undefined ? (description?.trim() || null) : existing.description,
      price: price != null ? Number(price) : existing.price,
      cost: cost != null ? Number(cost) : existing.cost,
      stock: stock != null ? Number(stock) : existing.stock,
      category_id: category_id !== undefined ? category_id : existing.category_id,
      is_active: is_active !== undefined && is_active !== null ? (is_active ? 1 : 0) : (existing.is_active ?? 1),
    };

    db.prepare(`
      UPDATE products
      SET name = ?, sku = ?, barcode = ?, description = ?, price = ?, cost = ?, stock = ?, category_id = ?, is_active = ?,
          updated_at = datetime('now')
      WHERE id = ?
    `).run(updates.name, updates.sku, updates.barcode, updates.description, updates.price, updates.cost, updates.stock, updates.category_id, updates.is_active, id);
    // image_path is updated via POST /:id/image

    const product = db.prepare('SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON p.category_id = c.id WHERE p.id = ?').get(id);
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE product (fails if product is used in any order)
router.delete('/:id', (req, res) => {
  try {
    const id = req.params.id;
    const existing = db.prepare('SELECT id, image_path FROM products WHERE id = ?').get(id);
    if (!existing) return res.status(404).json({ error: 'Product not found' });

    const usedInOrders = db.prepare('SELECT 1 FROM order_items WHERE product_id = ? LIMIT 1').get(id);
    if (usedInOrders) {
      return res.status(400).json({
        error: 'Cannot delete: this product is used in existing orders. Remove it from orders first or use a different product.',
      });
    }

    if (existing.image_path) {
      const imagePath = path.join(uploadsDir, existing.image_path);
      if (fs.existsSync(imagePath)) fs.unlinkSync(imagePath);
    }

    db.prepare('DELETE FROM products WHERE id = ?').run(id);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
